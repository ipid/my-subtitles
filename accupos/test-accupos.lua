if _G.aegisub.frame_from_ms(0) == nil then
    _G.aegisub.dialog.display({
        { class = "label", label = "【错误】\n\n本卡拉 OK 模板必须在打开视频之后才能运行。\n请打开一个视频后再运行本卡拉 OK 模板。\n如果没有视频，请点击「视频」→「使用空白视频」。\n", x = 0, y = 0 }
    }, { '好的，我现在就去打开视频' })
    _G.error()
end

local function trim(s)
    return s:gsub("^%s+", ""):gsub("%s+$", "")
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

--[[ 通过 subs 字段获取当前字幕内容（但是获取不到 Format: 行，反正这玩意也没人认） ]]
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
        if sub.class == "dialogue" and sub.comment == true and sub.effect:match("[Kk]araoke") then
            toInsert = _G.string.gsub(toInsert, 'Comment: ', 'Dialogue: ', 1)
        end

        if trim(sub.text) == '' then
            toInsert = ''
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
        _G.error('代码出错：accupos_init 返回了 NULL，这表明初始化出错。')
    end

    local result = {}

    local dialogue_num = accupos.n_dialogues
    for i = 1, dialogue_num do
        if accupos.dialogues[i - 1].raw == nil then
            _G.error(_G.string.format('代码出错：accupos->dialogues[%d].raw 为 NULL，这表明 accupos 内部出错了。', i - 1))
        end

        local d = {
            raw = ffi.string(accupos.dialogues[i - 1].raw),
            pos_x = accupos.dialogues[i - 1].pos_x,
            pos_y = accupos.dialogues[i - 1].pos_y,
            width = accupos.dialogues[i - 1].width,
            height = accupos.dialogues[i - 1].height,
            is_positioned = accupos.dialogues[i - 1].is_positioned,
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
