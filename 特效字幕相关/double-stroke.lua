--[[ 代码：计算每行轴所在位置 ]]
local util = _G.require('aegisub.util')
ipid = {}

if _G.aegisub.frame_from_ms(0) == nil then
    _G.aegisub.dialog.display({
        { class = "label", label = "【错误】\n\n本卡拉 OK 模板必须在打开视频之后才能运行。\n请打开一个视频后再运行本卡拉 OK 模板。\n如果没有视频，请点击「视频」→「使用空白视频」。\n", x = 0, y = 0 }
    }, { '好的，我现在就去打开视频' })
    _G.error()
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

local function shouldProcessLine(l)
    --[[
        此处的判断逻辑与 kara-templater.lua 保持一致，
        请参考原版中的 apply_templates 函数
    ]]
    return _G.type(l.start_time) == 'number' and
        _G.type(l.end_time) == 'number' and
        _G.type(l.text) == 'string' and
        _G.type(l.style) == 'string' and
        _G.type(l.effect) == 'string' and
        _G.type(l.comment) == 'boolean' and
        ((l.effect == '' and l.comment == false) or l.effect == 'karaoke' or l.effect == 'Karaoke')
end

local function getAllDialogueLines()
    local theSubs = getSpecificVar('subs')
    local theStyles = getSpecificVar('styles')

    local output = {}

    for i = 1, #theSubs do
        local l = theSubs[i]

        if shouldProcessLine(l) then
            local startFrame = _G.aegisub.frame_from_ms(l.start_time)
            local endFrame = _G.aegisub.frame_from_ms(l.end_time) - 1
            local text = l.text:gsub('%s+', '')

            local skip = false
            if theStyles[l.style].align ~= 2 or
                text:find('\\pos') ~= nil or
                text:find('\\move') ~= nil or
                text:find('\\an') ~= nil or
                util.trim(text) == '' then
                --[[ 仍然需要处理，但是分配到的 slot 为 -1，且跳过碰撞检测 ]]
                skip = true
            end

            if startFrame <= endFrame then
                output[#output + 1] = {
                    index = i,
                    startFrame = startFrame,
                    endFrame = endFrame,
                    skip = skip,
                }
            end
        end
    end

    return output
end

local function getLineToSlotTable(allLines)
    local events = {}

    for i = 1, #allLines do
        local l = allLines[i]

        events[#events + 1] = {
            index = l.index,
            type = 1,
            frame = l.startFrame,
            skip = l.skip,
        }
        if not l.skip then
            events[#events + 1] = {
                index = l.index,
                type = 0,
                frame = l.endFrame + 1,
                skip = l.skip,
            }
        end
    end

    local function sortEvents(a, b)
        if a.frame ~= b.frame then
            return a.frame < b.frame
        elseif a.type ~= b.type then
            return a.type < b.type
        end

        return a.index < b.index
    end

    _G.table.sort(events, sortEvents)

    local lineToSlot = {}
    local slots = {}

    for i = 1, #events do
        local ev = events[i]

        if ev.type == 0 then
            local targetSlot = lineToSlot[ev.index]
            slots[targetSlot] = nil
        else
            if ev.skip then
                lineToSlot[ev.index] = -1
            else
                local targetSlot = 1
                while slots[targetSlot] ~= nil do
                    targetSlot = targetSlot + 1
                end

                slots[targetSlot] = true
                lineToSlot[ev.index] = targetSlot
            end
        end
    end

    return lineToSlot
end

function ipid.convertSlotToPos(lineToSlot)
    local theMeta = getSpecificVar('meta')
    local output = {}

    for index, slot in _G.pairs(lineToSlot) do
        if slot < 0 then
            output[index] = ''
        else
            local x = _G.math.floor(theMeta.res_x / 2)
            local y = theMeta.res_y - MARGIN_BOTTOM - (slot - 1) * LINE_HEIGHT
            output[index] = _G.string.format('{\\pos(%d,%d)}', x, y)
        end
    end

    return output
end

linePos = ipid.convertSlotToPos(getLineToSlotTable(getAllDialogueLines()))