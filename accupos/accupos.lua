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

--[[ 通过 subs 字段获取当前字幕内容（但是获取不到 Format: 行，反正这玩意也没人认） ]]
local function getSubtitleContent()
    local assFile = {}
    local hasSection = {}

    local playResX = 0
    local playResY = 0

    local currSubs = getSpecificVar('subs')

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
        if sub.class == "dialogue" and sub.comment == true and sub.effect:match("[Kk]araoke") then
            toInsert = _G.string.gsub(toInsert, 'Comment: ', 'Dialogue: ', 1)
        end
        _G.table.insert(assFile, toInsert)
    end

    if playResX == 0 or playResY == 0 then
        playResX, playResY = _G.aegisub.video_size()
    end

    return _G.table.concat(assFile, '\n'), playResX, playResY
end

local function getPosWithAccupos(assText, playResX, playResY)
    local ffi = _G.require('ffi')
    ffi.cdef([[
        void *accupos_init(int32_t width, int32_t height, const char *ass_data, int32_t ass_data_len);
        void accupos_done(void *lib);
        int32_t accupos_get_dialogue_num(void *lib);
        const char *accupos_get_ith_raw(void *lib, int32_t i);
        int32_t accupos_get_ith_pos_x(void *lib, int32_t i);
        int32_t accupos_get_ith_pos_y(void *lib, int32_t i);
        int32_t accupos_get_ith_width(void *lib, int32_t i);
        int32_t accupos_get_ith_height(void *lib, int32_t i);
    ]])
    local lib = ffi.load(_G.jit.arch == 'x64' and 'accupos64' or 'accupos32')
    local voidptr = lib.accupos_init(playResX, playResY, assText, #assText)
    local result = {}

    local dialogue_num = lib.accupos_get_dialogue_num(voidptr)
    if dialogue_num < 0 then
        _G.error('代码出错：accupos 库返回 Dialogue 数量为 -1，这表明初始化出错。')
    end

    for i = 1, dialogue_num do
        local d = {
            raw = ffi.string(lib.accupos_get_ith_raw(voidptr, i - 1)),
            pos_x = lib.accupos_get_ith_pos_x(voidptr, i - 1),
            pos_y = lib.accupos_get_ith_pos_y(voidptr, i - 1),
            width = lib.accupos_get_ith_width(voidptr, i - 1),
            height = lib.accupos_get_ith_height(voidptr, i - 1),
        }

        if d.width > 0 and d.height > 0 then
            _G.table.insert(result, d)
        end
    end

    lib.accupos_done(voidptr)

    return result
end

local function dump(o)
    if _G.type(o) == 'table' then
        local s = '{ '
        for k, v in _G.pairs(o) do
            if _G.type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return _G.tostring(o)
    end
end

local assText, playResX, playResY = getSubtitleContent()
local positions = getPosWithAccupos(assText, playResX, playResY)
--[[ _G.error('\n\npositions = <'..dump(positions)..'>\n\n') ]]
local globalCounter = 1
local lastIndex = -1

local function startsWith(str, pattern)
    return str:sub(1,#pattern) == pattern
end

function getPos(index)
    if orgline.text:gsub('^%s+$', '') == '' then
        return ''
    end

    --[[ _G.error(_G.string.format('\n\norgline.raw = <%s>\n\norgline.comment = <%s>\n\norgline.effect = <%s>\n\n', orgline.raw, orgline.comment, orgline.effect)) ]]
    if lastIndex ~= index then
        lastIndex = index

        local lineRaw = orgline.raw
        if startsWith(lineRaw, 'Comment: ') then
            lineRaw = _G.string.gsub(lineRaw, 'Comment: ', 'Dialogue: ', 1)
        end
        lineRaw = _G.string.gsub(lineRaw, '%s+$', '')

        while positions[globalCounter].raw ~= lineRaw do
            globalCounter = globalCounter + 1

            if globalCounter > #positions then
                _G.error('代码出错：重建的字幕文件与实际字幕不匹配。')
            end
        end
    end

    local p = positions[globalCounter]
    return _G.string.format([[\pos(%d,%d)]], p.pos_x, p.pos_y)
end

function resetMargin()
    line.margin_l = 0
    line.margin_r = 0
    line.margin_t = 0
    line.margin_b = 0

    return ''
end