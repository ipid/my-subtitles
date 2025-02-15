local function errMsg(text, okBtn)
    _G.aegisub.dialog.display({
        { class = 'label', label = text, x = 0, y = 0 }
    }, { okBtn })
    _G.error(text)
end

if _G.aegisub.frame_from_ms(0) == nil then
    errMsg('【错误】\n\n本卡拉 OK 模板必须在打开视频之后才能运行。\n请打开一个视频后再运行本卡拉 OK 模板。\n如果没有视频，请点击「视频」→「使用空白视频」。\n', '好的，我现在就去打开视频')
end

local function trim(to_trim)
    --[[ 这里必须用一个中间变量，不然会返回多个参数 ]]
    local result = _G.string.gsub(to_trim, '^%s+', ''):gsub('%s+$', '')
    return result
end

local function getSpecificVar(targetName)
    local level = 1

    while _G.debug.getinfo(level) ~= nil do
        local i = 1

        while true do
            local name, value = _G.debug.getlocal(level, i)

            if name == targetName then
                return value
            elseif name == nil then
                break
            end

            i = i + 1
        end

        level = level + 1
    end

    return nil
end

--[[ 通过 subs 对象获取当前字幕内容（但是获取不到 Format:，不过 accupos（libass）兼容） ]]
local function getSubtitleContent(currSubs)
    local assFile = {}
    local hasSection = {}

    local playResX = 0
    local playResY = 0

    for i = 1, #currSubs do
        local sub = currSubs[i]

        if sub.key == 'PlayResX' then
            playResX = _G.tonumber(sub.value)
        elseif sub.key == 'PlayResY' then
            playResY = _G.tonumber(sub.value)
        end

        local section = sub.section

        if not hasSection[section] then
            _G.table.insert(assFile, '\n' .. section)
            hasSection[section] = true
        end

        local toInsert = sub.raw
        --[[ 把符合 kara-templater 匹配模板条件的 Comment 替换成 Dialogue ]]
        if sub.class == 'dialogue' and sub.comment == true and sub.effect:match('[Kk]araoke') then
            toInsert = _G.string.gsub(toInsert, 'Comment: ', 'Dialogue: ', 1)
        end

        if sub.class == 'dialogue' then
            if trim(sub.text) == '' then
                toInsert = ''
            end
            if _G.aegisub.frame_from_ms(sub.start_time) >= _G.aegisub.frame_from_ms(sub.end_time) then
                toInsert = ''
            end
        end

        _G.table.insert(assFile, trim(toInsert))
    end

    if playResX == 0 or playResY == 0 then
        playResX, playResY = _G.aegisub.video_size()
    end

    return _G.table.concat(assFile, '\n'), playResX, playResY
end

local function getPosWithAccupos(assText, playResX, playResY)
    local ffi = _G.require('ffi')
    ffi.cdef([[
        typedef struct {
            double pos_x, pos_y;
            const char *raw;
            int32_t width, height;
            int32_t is_positioned;
        } Accupos_Dialogue;

        typedef struct Accupos_LibassPrivate Accupos_LibassPrivate;

        typedef struct {
            Accupos_LibassPrivate *libass;
            Accupos_Dialogue *dialogues;
            int32_t n_dialogues;
        } Accupos_Library;

        Accupos_Library *accupos_init(
            int32_t width, int32_t height,
            const char *ass_data, int32_t ass_data_len
        );

        void accupos_done(Accupos_Library *lib);
    ]])
    local dll = ffi.load(_G.jit.arch == 'x64' and 'accupos64' or 'accupos32')

    local accupos = dll.accupos_init(playResX, playResY, assText, #assText)
    if accupos == nil then
        errMsg('\n代码出错：accupos_init 返回了 NULL，这表明初始化出错。', '好的，我会给开发者报告错误')
    end

    local result = {}

    local dialogueNum = accupos.n_dialogues
    for i = 1, dialogueNum do
        local origD = accupos.dialogues[i - 1]

        if origD.raw == nil then
            errMsg(_G.string.format('【代码出错】\n\naccupos->dialogues[%d].raw 为 NULL，这表明 accupos 内部出错了。\n', i - 1), '好的，我会给开发者报告错误')
        end

        local d = {
            raw = ffi.string(origD.raw),
            posX = origD.pos_x,
            posY = origD.pos_y,
            width = origD.width,
            height = origD.height,
            isPositioned = (origD.is_positioned ~= 0),
        }

        if d.width > 0 and d.height > 0 then
            _G.table.insert(result, d)
        end
    end

    dll.accupos_done(accupos)

    return result
end

local function startsWith(str, pattern)
    return str:sub(1, #pattern) == pattern
end

local currSubs = getSpecificVar('subs')
local currStyles = getSpecificVar('styles')
local assText, playResX, playResY = getSubtitleContent(currSubs)
local positions = getPosWithAccupos(assText, playResX, playResY)
local globalCounter = 1
local lastIndex = -1

function findMatchingLine(index)
    --[[ 这里必须用 text_stripped 做判断，因为 libass 也不会输出纯注释行（例：只有一个 {?} 的行） ]]
    if trim(orgline.text_stripped) == '' then
        return ''
    end
    if _G.aegisub.frame_from_ms(orgline.start_time) >= _G.aegisub.frame_from_ms(orgline.end_time) then
        return ''
    end

    if lastIndex ~= index then
        local lineRaw = trim(orgline.raw)
        if startsWith(lineRaw, 'Comment: ') then
            lineRaw = _G.string.gsub(lineRaw, 'Comment: ', 'Dialogue: ', 1)
        end

        while positions[globalCounter].raw ~= lineRaw do
            globalCounter = globalCounter + 1

            if globalCounter > #positions then
                _G.error(_G.string.format('【代码出错】\n\n重建的字幕文件与实际字幕不匹配。\n当前行为 <%s>，\n在第 %d 行后找不到该行。\n', orgline.raw, lastIndex))
            end
        end

        lastIndex = index
    end

    return ''
end

function getPos()
    local p = positions[globalCounter]

    if p.isPositioned then
        return ''
    end

    local posX = _G.string.format('%.2f', p.posX):gsub('%.?0+$', '')
    local posY = _G.string.format('%.2f', p.posY):gsub('%.?0+$', '')
    return _G.string.format([[\pos(%d,%d)]], posX, posY)
end

function resetMargin()
    line.margin_l = 0
    line.margin_r = 0
    line.margin_t = 0
    line.margin_b = 0

    return ''
end

function removeBrackets(text)
    return text:gsub('{', ''):gsub('}', '')
end

--[[ 通用的 ASS 解析器 ]]
local Parser = {
    VALID_TAGS = { '1a', '1c', '2a', '2c', '3a', '3c', '4a', '4c',
                   'alpha', 'an', 'a', 'blur', 'bord', 'be', 'b', 'clip', 'c', 'distort', 'fade', 'fscx',
                   'fscy', 'fsvp', 'fad', 'fax', 'fay', 'frs', 'frx', 'fry', 'frz', 'fsc', 'fsp', 'fe',
                   'fn', 'fr', 'fs', 'iclip', 'i', 'jitter', 'kf', 'ko', 'kt', 'k', 'movevc', 'mover',
                   'move', 'org', 'pbo', 'pos', 'p', 'q', 'rnds', 'rndx', 'rndy', 'rndz', 'rnd', 'r',
                   'shad', 's', 't', 'u', 'xbord', 'xshad', 'ybord', 'yshad', 'z' }
}

function Parser.tryNumber(x)
    local y = _G.tonumber(x)
    if y ~= nil then
        return y
    end
    return x
end

function Parser.getUtils(text)
    local i = 1

    local function peek()
        return text:sub(i, i)
    end

    local function next(delta)
        if delta == nil then
            delta = 1
        end

        local c = peek()
        i = i + delta
        return c
    end

    local function match(x)
        return text:sub(i, i + #x - 1) == x
    end

    local function remember()
        return i
    end

    local function restore(x)
        i = x
    end

    return peek, next, match, remember, restore
end

function Parser.Whitespaces(peek, next, match, remember, restore)
    while true do
        local c = peek()
        if c ~= ' ' and c ~= '\t' and c ~= '　' then
            break
        end

        next()
    end
end

function Parser.NonChar(charList, peek, next, match, remember, restore)
    local output = {}
    while true do
        local c = peek()
        if c == '' then
            break
        end

        local matched = false
        for i = 1, #charList do
            if c == charList[i] then
                matched = true
                break
            end
        end

        if matched then
            break
        end

        _G.table.insert(output, next())
    end

    if #output == 0 then
        return nil
    else
        return _G.table.concat(output)
    end
end

function Parser.TagParamListItem(peek, next, match, remember, restore)
    Parser.Whitespaces(peek, next, match, remember, restore)

    local maybeTag = Parser.Tag(peek, next, match, remember, restore)
    if maybeTag ~= nil then
        return maybeTag
    end

    local normalItem = Parser.NonChar({ ',', ')', '}' }, peek, next, match, remember, restore)
    if normalItem ~= nil then
        normalItem = trim(normalItem)
    end
    return normalItem
end

function Parser.TagParamList(peek, next, match, remember, restore)
    local loc = remember()

    if peek() ~= '(' then
        return nil
    end
    next()

    local output = {}

    while true do
        local listItem = Parser.TagParamListItem(peek, next, match, remember, restore)
        _G.table.insert(output, Parser.tryNumber(listItem)) --[[ lua 没法插入 nil，但此处语义和 VSFilter / libass 恰巧一致 ]]

        if peek() == ',' then
            next()
        end
        Parser.Whitespaces(peek, next, match, remember, restore)

        local c = peek()
        if c == ')' or c == '}' or c == '' then
            break
        end
    end

    if peek() == ')' then
        next()
        return output
    else
        restore(loc)
        return nil
    end
end

function Parser.Tag(peek, next, match, remember, restore)
    local loc = remember()

    if peek() ~= '\\' then
        return nil, nil
    end
    next()

    Parser.Whitespaces(peek, next, match, remember, restore)
    local validTagName = nil

    for i = 1, #Parser.VALID_TAGS do
        local candidate = Parser.VALID_TAGS[i]
        if match(candidate) then
            validTagName = candidate
            next(#candidate)
            break
        end
    end

    if validTagName == nil then
        restore(loc)
        return nil, nil
    end

    Parser.Whitespaces(peek, next, match, remember, restore)

    local tagParams = Parser.TagParamList(peek, next, match, remember, restore)
    if tagParams == nil then
        local singleParam = Parser.NonChar({ ' ', '\\', '}' }, peek, next, match, remember, restore)
        if singleParam ~= nil then
            singleParam = trim(singleParam)
        else
            singleParam = ''
        end
        if singleParam == '' then
            tagParams = {}
        else
            tagParams = { Parser.tryNumber(singleParam) }
        end
    end

    return validTagName, tagParams
end

function Parser.NonTag(peek, next, match, remember, restore)
    local output = {}

    if peek() == '\\' then
        output = { next() }
    end

    local nonTag = Parser.NonChar({ '\\', '}' }, peek, next, match, remember, restore)
    if nonTag ~= nil then
        _G.table.insert(output, nonTag)
    end

    if #output == 0 then
        return nil
    else
        return _G.table.concat(output)
    end
end

function Parser.TagBlock(peek, next, match, remember, restore)
    local loc = remember()

    if peek() ~= '{' then
        return nil
    end

    next()

    local output = {}

    while true do
        local tagName, tagParams = Parser.Tag(peek, next, match, remember, restore)
        local nonTag = nil

        if tagName ~= nil then
            _G.table.insert(output, { name = tagName, params = tagParams })
        else
            nonTag = Parser.NonTag(peek, next, match, remember, restore)
        end

        if tagName == nil and nonTag == nil then
            break
        end
    end

    if peek() == '}' then
        next()
        return output
    else
        restore(loc)
        return nil
    end
end

function Parser.Dialogue(text)
    local peek, next, match, remember, restore = Parser.getUtils(text)
    local output = {}

    Parser.Whitespaces(peek, next, match, remember, restore)
    while true do
        local tagBlock = Parser.TagBlock(peek, next, match, remember, restore)

        if tagBlock ~= nil then
            _G.table.insert(output, {
                type = 'block',
                tags = tagBlock
            })
        else
            local normalText = Parser.NonChar({ '{' }, peek, next, match, remember, restore)
            if normalText ~= nil then
                _G.table.insert(output, {
                    type = 'text',
                    text = normalText
                })
            else
                break
            end
        end
    end

    return output
end

local STYLE_KEY_FOR_TAG = {
    ['c'] = 'color1',
    ['1c'] = 'color1',
    ['2c'] = 'color2',
    ['3c'] = 'color3',
    ['4c'] = 'color4',
    ['1a'] = 'color1',
    ['2a'] = 'color2',
    ['3a'] = 'color3',
    ['4a'] = 'color4',
    ['bord'] = 'outline',
    ['shad'] = 'shadow',
}

local function analyzedParamsForStyleAndTag(st, tagName)
    local key = STYLE_KEY_FOR_TAG[tagName]
    if key == nil then
        return nil
    end
    if tagName == 'c' or tagName == '1c' or tagName == '2c' or tagName == '3c' or tagName == '4c' then
        return { '&H' .. st[key]:sub(5, 10) .. '&' }
    end
    if tagName == '1a' or tagName == '2a' or tagName == '3a' or tagName == '4a' then
        return { '&H' .. st[key]:sub(3, 4) .. '&' }
    end

    return { st[key] }
end

local function transformTagWithStrategies(tagName, tagParams, strategies)
    if tagName == 'r' then
        local rTarget = tagParams[1]
        if rTarget == nil or currStyles[rTarget] == nil then
            rTarget = ''
        end

        local st = line.styleref
        if rTarget ~= '' then
            st = currStyles[rTarget]
        end

        local transformedOutputs = {}
        for strategyTagName, strategy in _G.pairs(strategies) do
            local analyzedParams = analyzedParamsForStyleAndTag(st, strategyTagName)
            _G.table.insert(transformedOutputs, strategy.func(strategyTagName, analyzedParams, st))
        end

        return '\\r' .. rTarget .. _G.table.concat(transformedOutputs)

    elseif strategies[tagName] ~= nil then
        local strategy = strategies[tagName]
        if strategy.type == 'transform' then
            if #tagParams == 0 then
                --[[ ASS 不带参数时参数为样式默认值，试着解析一下 ]]
                local possibleParam = analyzedParamsForStyleAndTag(line.styleref, tagName)
                if possibleParam ~= nil then
                    tagParams = possibleParam
                end
            end

            --[[ `func` 返回的是带 \ 的标签内容 ]]
            return strategy.func(tagName, tagParams)
        elseif strategy.type == 'discard' then
            return ''
        end
    end

    return nil
end

local function parsedTagToString(t)
    local out = {}

    _G.table.insert(out, '\\' .. t.name)
    if #t.params == 0 then
        --[[ 不需要插入参数 ]]
    elseif #t.params == 1 then
        _G.table.insert(out, t.params[1])
    else
        _G.table.insert(out, '(')
        for k = 1, #t.params do
            _G.table.insert(out, t.params[k])
            if k ~= #t.params then
                _G.table.insert(out, ',')
            end
        end
        _G.table.insert(out, ')')
    end

    return _G.table.concat(out)
end

local function transformTextWithStrategies(text, strategies)
    if text:find('{') == nil then
        --[[ 优化处理速度 ]]
        return text
    end

    local dialogue = Parser.Dialogue(text)
    local output = {}

    for i = 1, #dialogue do
        local blockOrText = dialogue[i]
        if blockOrText.type == 'text' then
            _G.table.insert(output, blockOrText.text)
        else
            local blockOutput = {}

            for j = 1, #blockOrText.tags do
                local tag = blockOrText.tags[j]
                local newTag = transformTagWithStrategies(tag.name, tag.params, strategies)

                if newTag ~= nil then
                    _G.table.insert(blockOutput, newTag)
                else
                    _G.table.insert(blockOutput, parsedTagToString(tag))
                end
            end

            _G.table.insert(output, '{' .. _G.table.concat(blockOutput) .. '}')
        end
    end

    return _G.table.concat(output)
end

local DEFAULT_4A = EB_SHADOW_COLOR:match("\\4a&[^&]+&")
local DEFAULT_4C = EB_SHADOW_COLOR:match("\\4c&[^&]+&")

function layer0Text()
    return transformTextWithStrategies(orgline.text, {
        shad = {
            type = 'transform',
            func = function(tagName, tagParams)
                local shad = tagParams[1]
                return '\\shad' .. (shad * (1 + EB_SHADOW_RATIO) + EB_WIDTH)
            end
        },
        ['4a'] = { type = 'discard', func = function()
            return DEFAULT_4A
        end },
        ['4c'] = { type = 'discard', func = function()
            return DEFAULT_4C
        end },
    })
end

function layer1Text()
    return transformTextWithStrategies(orgline.text, {
        bord = {
            type = 'transform',
            func = function(tagName, tagParams)
                local bord = tagParams[1]
                return '\\bord' .. (bord + EB_WIDTH)
            end
        },
        ['2c'] = { type = 'transform', func = function(tagName, tagParams)
            return '\\3c' .. tagParams[1]
        end },
        ['3c'] = { type = 'discard', func = function(_, _, targetSt)
            return '\\3c' .. analyzedParamsForStyleAndTag(targetSt, '2c')[1]
        end },
    })
end

function layer2Text()
    return transformTextWithStrategies(orgline.text, {
        ['shad'] = { type = 'discard', func = function()
            return '\\shad0'
        end },
    })
end