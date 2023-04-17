local inspect = require('inspect')

local function trim(to_trim)
    --[[ 这里必须用一个中间变量，不然会返回多个参数 ]]
    local result = _G.string.gsub(to_trim, '^%s+', ''):gsub('%s+$', '')
    return result
end

local currStyles = {
    ["Staff黑"] = {
        align = 2,
        angle = 0,
        bold = false,
        borderstyle = 1,
        class = "style",
        color1 = "&H00555652&",
        color2 = "&H006E6E6E&",
        color3 = "&H00FFFFFF&",
        color4 = "&H00AFAFAF&",
        encoding = 1,
        fontname = "ipid-ZhuZiCN-TsukuJP-E",
        fontsize = 92,
        italic = false,
        margin_b = 70,
        margin_l = 10,
        margin_r = 10,
        margin_t = 70,
        margin_v = 70,
        name = "Staff黑",
        outline = 12,
        raw = "Style: Staff黑,ipid-ZhuZiCN-TsukuJP-E,92,&H00555652,&H006E6E6E,&H00FFFFFF,&H00AFAFAF,0,0,0,0,100,100,0,0,1,12,7,2,10,10,70,1",
        relative_to = 2,
        scale_x = 100,
        scale_y = 100,
        section = "[V4+ Styles]",
        shadow = 7,
        spacing = 0,
        strikeout = false,
        underline = false
    },
    ["个活-鲤鱼"] = {
        align = 2,
        angle = 0,
        bold = false,
        borderstyle = 1,
        class = "style",
        color1 = "&H00783BF5&",
        color2 = "&H00A36DE8&",
        color3 = "&H00FFFFFF&",
        color4 = "&H00A695FF&",
        encoding = 1,
        fontname = "ipid-ZhuZiCN-TsukuJP-E",
        fontsize = 92,
        italic = false,
        margin_b = 70,
        margin_l = 10,
        margin_r = 10,
        margin_t = 70,
        margin_v = 70,
        name = "个活-鲤鱼",
        outline = 12,
        raw = "Style: 个活-鲤鱼,ipid-ZhuZiCN-TsukuJP-E,92,&H00783BF5,&H00A36DE8,&H00FFFFFF,&H00A695FF,0,0,0,0,100,100,0,0,1,12,7,2,10,10,70,1",
        relative_to = 2,
        scale_x = 100,
        scale_y = 100,
        section = "[V4+ Styles]",
        shadow = 7,
        spacing = 0,
        strikeout = false,
        underline = false
    },
    ["星-全员"] = {
        align = 2,
        angle = 0,
        bold = false,
        borderstyle = 1,
        class = "style",
        color1 = "&H009B46A5&",
        color2 = "&H00A256AB&",
        color3 = "&H00FFFFFF&",
        color4 = "&H20AE6393&",
        encoding = 1,
        fontname = "ipid-ZhuZiCN-TsukuJP-E",
        fontsize = 92,
        italic = false,
        margin_b = 70,
        margin_l = 10,
        margin_r = 10,
        margin_t = 70,
        margin_v = 70,
        name = "星-全员",
        outline = 12,
        raw = "Style: 星-全员,ipid-ZhuZiCN-TsukuJP-E,92,&H009B46A5,&H00A256AB,&H00FFFFFF,&H20AE6393,0,0,0,0,100,100,0,0,1,12,7,2,10,10,70,1",
        relative_to = 2,
        scale_x = 100,
        scale_y = 100,
        section = "[V4+ Styles]",
        shadow = 7,
        spacing = 0,
        strikeout = false,
        underline = false
    },
}

--[[ 参数：额外描边的大小 ]] EB_WIDTH = 2.5
--[[ 参数：额外阴影的大小比、颜色/透明度 ]] EB_SHADOW_RATIO = 0.7;
EB_SHADOW_COLOR = [[{\4c&H727272&\4a&H96&}]]

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
            _G.table.insert(transformedOutputs, strategy.func(strategyTagName, analyzedParams))
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
        ['3c'] = { type = 'discard', func = function()
            return '\\3c' .. analyzedParamsForStyleAndTag(line.styleref, '3c')[1]
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

line = {
    styleref = {
        align = 2,
        angle = 0,
        bold = false,
        borderstyle = 1,
        class = "style",
        color1 = "&H00FFFFFF&",
        color2 = "&H000000FF&",
        color3 = "&H00000000&",
        color4 = "&H00000000&",
        encoding = 1,
        fontname = "Arial",
        fontsize = 48,
        italic = false,
        margin_b = 10,
        margin_l = 10,
        margin_r = 10,
        margin_t = 10,
        margin_v = 10,
        name = "Default",
        outline = 1,
        raw = "Style: Default,Arial,48,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,2,2,10,10,10,1",
        relative_to = 2,
        scale_x = 100,
        scale_y = 100,
        section = "[V4+ Styles]",
        shadow = 13,
        spacing = 0,
        strikeout = false,
        underline = false,
    }
}

orgline = {
    text = [[「{\r星-全员}纳尼纳尼纳尼{\r}」]]
}

print('Layer 0:', layer0Text())
print('Layer 1:', layer1Text())
print('Layer 2:', layer2Text())
