local SERVER = "https://thespikecross.up.railway.app/"
local KEY_FILE = "/sdcard/.key"

-- ===== WEBHOOK CONFIG =====
local WEBHOOK_URL = "https://discord.com/api/webhooks/1475377973069611099/zKJ-o5Rq5xEyIRoytVaqvPxmEKKKWTy0rQP9PWL9ARtk3PdvXIps5Bulxvv-kHh6Bfw1"

-- ===== UTILS =====
local function getDeviceID()
  local id = gg.getFile()
  return tostring(id):gsub("[^%w]", ""):sub(1, 20)
end

local function saveKeyLocal(key)
  local f = io.open(KEY_FILE, "w")
  if f then
    f:write(key)
    f:close()
  end
end

local function loadKeyLocal()
  local f = io.open(KEY_FILE, "r")
  if f then
    local key = f:read("*l")
    f:close()
    return key and key:match("^%s*(.-)%s*$")
  end
  return nil
end

local function deleteKeyLocal()
  os.remove(KEY_FILE)
end

-- ===== WEBHOOK SENDER =====
local function sendWebhook(key, status, fromLocal)
  if not WEBHOOK_URL or WEBHOOK_URL == "" or WEBHOOK_URL:find("XXXXXX") then
    return
  end

  local sourceType = fromLocal and "🔁 Saved Key (Auto-Login)" or "🆕 New Key (Manual Input)"
  local timeNow = os.date("%Y-%m-%d %H:%M:%S")
  local statusIcon = (status == "valid") and "✅" or "❌"

  local payload = string.format(
    '{"username":"Key Logger","embeds":[{"title":"%s Key Login Detected","color":5763719,"fields":[' ..
    '{"name":"🔑 Key","value":"`%s`","inline":true},' ..
    '{"name":"📌 Source","value":"%s","inline":false},' ..
    '{"name":"🕐 Time","value":"%s","inline":false}' ..
    '],"footer":{"text":"Game Guardian Key System"}}]}',
    statusIcon,
    key,
    sourceType,
    timeNow
  )

  pcall(function()
    gg.makeRequest(WEBHOOK_URL, {
      ["Content-Type"] = "application/json"
    }, payload)
  end)
end

-- ===== SERVER VALIDATION =====
local function validateKey(key)
  local deviceId = getDeviceID()
  local url = SERVER .. "/validate?key=" .. key .. "&device=" .. deviceId
  local res = gg.makeRequest(url)
  if type(res) == "table" then
    return res.content or ""
  end
  return ""
end

-- ===== HANDLE RESPONSE =====
local function handleResponse(response, fromLocal)
  local parts = {}
  for p in response:gmatch("[^|]+") do
    table.insert(parts, p)
  end

  if parts[1] == "valid" then
    if parts[2] == "permanent" then
      if not fromLocal then
        gg.alert("✅ PERMANENT Key active!\nKey saved for next session.")
      end
      return true
    else
      local expiry = parts[3] or "?"
      if fromLocal then
        gg.toast("✅ TRIAL Key active | Valid until: " .. expiry)
      else
        gg.alert("✅ TRIAL Key active!\nValid until: " .. expiry .. "\nKey saved for next session.")
      end
      return true
    end
  elseif response == "expired" then
    gg.alert("❌ Trial key EXPIRED!\nContact admin to renew.")
    deleteKeyLocal()
    return false
  elseif response == "used_other_device" then
    gg.alert("❌ Key already used on another device!\nContact admin to reset device.")
    deleteKeyLocal()
    return false
  elseif response == "invalid_key" then
    gg.alert("❌ Invalid key!\nCheck your key again.")
    deleteKeyLocal()
    return false
  elseif response == "revoked" then
    gg.alert("❌ Key has been revoked by admin!")
    deleteKeyLocal()
    return false
  else
    if fromLocal then
      gg.alert("❌ Cannot connect to server!\nCheck your internet connection.")
    else
      gg.alert("❌ Failed to connect to server!\nCheck your internet connection.")
    end
    return false
  end
end

-- ===== MAIN =====
local function maingetky()
  local savedKey = loadKeyLocal()

  if savedKey then
    gg.toast("🔑 Checking saved key...")
    local response = validateKey(savedKey)
    local valid = handleResponse(response, true)

    if not valid then
      savedKey = nil
    else
      sendWebhook(savedKey, "valid", true)
      goto run_script
    end
  end

  if not savedKey then
    local input = gg.prompt(
      { "🔑 Enter Activation Key" },
      { "" },
      { "text" }
    )
    if not input then return end

    local key = input[1]

    if key == "" then
      gg.alert("❌ Key cannot be empty!")
      return
    end

    local response = validateKey(key)
    local valid = handleResponse(response, false)

    if valid then
      saveKeyLocal(key)
      sendWebhook(key, "valid", false)
    else
      return
    end
  end

  ::run_script::
  
if gg.getTargetPackage() ~= "com.daerisoft.thespikerm" then
  gg.alert("❌ Script can only be executed in The Spike")
  os.exit()
end
local target = gg.getTargetInfo()
if not target or not target.versionName or not target.versionCode then
    gg.alert("⚠️ Failed to detect game version!")
    os.exit()
end
local requiredCode = 8000116
local requiredName = "[8.0.116] 8.0.116"
if target.versionName ~= requiredName or target.versionCode ~= requiredCode then
    gg.alert("❌ Script is only for version " .. requiredName .. " (Code: " .. requiredCode .. ")!\nYour current version: " .. target.versionName .. " (Code: " .. target.versionCode .. ")")
    os.exit()
end

gg.toast(" The Spike Cross (" .. target.versionName .. " | Code: " .. target.versionCode .. ")")

function editOffset(results, offset, value, flags)
    flags = flags or gg.TYPE_DOUBLE
    if not results or #results == 0 then
        return
    end
    local edits = {}
    for _, v in ipairs(results) do
        local addr = v.address + offset
        edits[#edits + 1] = {address = addr, flags = flags, value = value}
    end
    gg.setValues(edits)
end

function hiddenRefine(results, offset, targetValue, flags)
    flags = flags or gg.TYPE_DOUBLE
    local refined, check = {}, {}
    for _, v in ipairs(results) do
        check[#check+1] = {address = v.address + offset, flags = flags}
    end
    check = gg.getValues(check)
    for _, v in ipairs(check) do
        if tonumber(v.value) == tonumber(targetValue) then
            refined[#refined+1] = v
        end
    end
    return refined
end

function refineByRange(results, offset, rangeStr, flags)
    flags = flags or gg.TYPE_DOUBLE
    local refined = {}
    if not results or #results == 0 then
        return refined
    end
    local minVal, maxVal = rangeStr:match("^(%-?%d+%.?%d*)%s*~%s*(%-?%d+%.?%d*)$")
    minVal = tonumber(minVal)
    maxVal = tonumber(maxVal)
    if not minVal or not maxVal then
        return results
    end
    if minVal > maxVal then
        minVal, maxVal = maxVal, minVal
    end
    local check = {}
    for _, v in ipairs(results) do
        check[#check+1] = {address = v.address + offset, flags = flags}
    end
    check = gg.getValues(check)
    for _, v in ipairs(check) do
        local val = tonumber(v.value)
        if val and val >= minVal and val <= maxVal then
            refined[#refined+1] = v
        end
    end
    return refined
end

gg.toast("Script By Master Township ✅")
gg.toast("Hello Premium V1 User")
gg.alert("Script The Spike [8.0.116] 8.0.116 By : Master Township\nTiktok : @master.townshipreal\nYT : @mastertownship2023")
gg.sleep(200)
local pesan_kombinasi = "[ INDONESIA ]\nHarap dibaca terlebih dahulu sebelum ke menu script. Kepada seluruh user kalian wajib menggunakan gameguardian versi terbaru 101.4 atau kalian bisa download menggunakan tautan yang sudah saya bagikan.\nKarena script ini hanya mendukung di GameGuardian versi 101.4\n\n[ ENGLISH ]\nPlease read carefully before proceeding to the script menu. To all users, you are required to use the latest GameGuardian version 101.4, or you can download it using the link I have provided.\nBecause this script only supports GameGuardian version 101.4"
gg.alert(pesan_kombinasi, 'OK')
local TARGET_VERSION  = "101.4"
local MIN_VERSION_INT = 10104
if gg.VERSION ~= TARGET_VERSION or gg.VERSION_INT < MIN_VERSION_INT then
    gg.alert(
        "❌ Invalid GameGuardian version!\n\n" ..
        "Required Version : " .. TARGET_VERSION .. "\n" ..
        "Version Code    : " .. MIN_VERSION_INT
    )
    os.exit()
end
gg.toast("✅ Verification successful! Loading script...")
gg.setVisible(true)
-- ===== GLOBAL VARIABLES =====
local currentMenu = 1
local dummyEnemyStatus = false
local dummySnapshot = {}
local skyServeStatus = false
local skyServeSnapshot = {}
local AutoWinStatus = false
local AutoWinSnapshot = {}
local ServeStatus = false
local ServeSnapshot = {}
local RecruitmentStatus = false
local RecruitmentSnapshot = {}
local cachedFinalResults = nil
local rawNameMap = {}
local rawRankMap = {}
-- ===== MAIN MENU =====
function main()
    currentMenu = 1
    local realTime = os.date("%H:%M:%S")
    local realDate = os.date("%B %d, %Y")
    local timeInfo = "⏰ Time : " .. realTime .. " | Date : " .. realDate
    local gameName = "The Spike Cross"
    local gameVersion = "[8.0.116] 8.0.116"
    local architecture = "Architecture : Arm64-v8a"
    local creditInfo = "Credit : Master Township"
    local titleHeader = "• Main Menu •\n" .. gameName .. " [Premium V1] 1.7.2 - " .. gameVersion .. "\n" .. architecture .. "\n" .. timeInfo .. "\n" .. creditInfo
    local menu = gg.choice({
        " Manage Player Menu",
        " Gameplay Menu",
        " Lobby Menu",
        " Misc Menu", 
        " Exit"
    }, 0, titleHeader)   
    if menu == 1 then 
        CharacterMenu()
    elseif menu == 2 then
        GameplayMenu()
    elseif menu == 3 then 
       LobbyMenu()
   elseif menu == 4 then
        MiscMenu()
    elseif menu == 5 then 
        gg.clearResults() 
        os.exit() 
    end
end
-- ===== MANAGE PLAYER MENU =====
costumeResetVerified = costumeResetVerified or false
function CharacterMenu()
    currentMenu = 2
    if not costumeResetVerified then
        local alert = gg.alert("Apakah Semua Kostum Anda Sudah Di Reset Ke Default?\n\nHave All Your Costume Been Reset To Default?", "YES", "NO")    
        if alert ~= 1 then
            main()
            return
        end
        costumeResetVerified = true
    end
    local menu = gg.choice({
        " All Character ( Stat )",
        " All Character ( Skin + Stat )",
        " All Character ( Skin + Max Stat )",
        " Inject All Character", 
        " Change Height All Character",
        " Mastery", 
        " Return"
    }, 0, "• Manage Player Menu •")
    if menu == 1 then
        EditStatOnly()
    elseif menu == 2 then
        SkinStat()
    elseif menu == 3 then
        SkinMaxStat()
    elseif menu == 4 then
        InjectionChar()
    elseif menu == 5 then
        HeightChar()
    elseif menu == 6 then
        Mastery()
    elseif menu == 7 then
        main()
    end
end
-- ===== MASTERY MENU =====
function Mastery()
    currentMenu = 15
    local menu = gg.choice({
        " Tier Mastery",
        " Change Mastery",
        " Return"
    }, 0, "• Mastery Menu •")
    if menu == 1 then
        TierMastery()
    elseif menu == 2 then
        ChangeMastery()
    elseif menu == 3 then
        CharacterMenu()
    end
end
-- ===== ALL CHARACTER ( STAT ) MENU =====
function EditStatOnly()
    currentMenu = 9
    local menu = gg.choice({
    	" Position Wing Spiker", 
        " Position Middle Blocker", 
        " Position Setter",
        " Return"
    }, 0, "• All Character ( Stat ) Menu •")
    if menu == 1 then
        WingSpikerMenu()
    elseif menu == 2 then
        MiddleBlockerMenu()
    elseif menu == 3 then
        SetterMenu()
    elseif menu == 4 then
        CharacterMenu()
    end
end
-- ===== GAMEPLAY MENU =====
function GameplayMenu()
    currentMenu = 3
    local skyStatusText = skyServeStatus and " [ ON ]" or " [ OFF ]"
    local statusText = dummyEnemyStatus and " [ ON ]" or " [ OFF ]"
    local AutoWin = AutoWinStatus and " [ ON ]" or " [ OFF ]"
    local ServeText = ServeStatus and " [ ON ]" or " [ OFF ]"
    local menu = gg.choice({
        " Stamina",
        " Unlimited Duration Skill", 
        " High Field Of View", 
        " Modify Score",
        " Volleyball Skin", 
        " Map in Game", 
        " Sky Serve" .. skyStatusText, 
        " Dummy Enemy" .. statusText,
        " Auto Win Lite" .. AutoWin, 
        " Auto Serve" .. ServeText, 
        " Return"
    }, 0, "• Gameplay Menu •")    
    if menu == 1 then
        StaminaMenu()
    elseif menu == 2 then
        UnlimitedDurationSkillMenu()
    elseif menu == 3 then
        HighFov()
        GameplayMenu()
    elseif menu == 4 then
        EditScoreMenu()
    elseif menu == 5 then
        MenuVolleyballSkin()
    elseif menu == 6 then
        MenuBackground()
    elseif menu == 7 then
        ToggleSkyServe()
        GameplayMenu()
    elseif menu == 8 then
        ToggleDummyEnemy()
        GameplayMenu()
   elseif menu == 9 then
        ToggleAutoWinLite()
        GameplayMenu()
    elseif menu == 10 then
        ToggleServe()
        GameplayMenu()
    elseif menu == 11 then
        main()
    end
end
-- ===== LOBBY MENU =====
function LobbyMenu()
    currentMenu = 7
    local menu = gg.choice({
        " Unlimited Currency ( Visual )", 
        " Hide UID",
        " Return"
    }, 0, "• Lobby Menu •")
    if menu == 1 then
        MenuCurrency() 
        LobbyMenu()
    elseif menu == 2 then
        HideUID()
        LobbyMenu()
    elseif menu == 3 then
        main()
    end
end
-- ===== STAMINA MENU =====
function StaminaMenu()
    currentMenu = 4
    local menu = gg.choice({
        " Unlimited Stamina - Part 1",
        " Unlimited Stamina - Part 2",
        " Unlimited Stamina - Part 3",
        " Unlimited Stamina - Part 4",
        " Clear Saved Items",
        " Return"
    }, 0, "• Stamina Menu •")
    if menu == 1 then
        UnlimitedStaminaTournament(100)
    elseif menu == 2 then
        UnlimitedStaminaTournament(115)
    elseif menu == 3 then
        UnlimitedStaminaTournament(300)
    elseif menu == 4 then
        UnlimitedStaminaTournament(550)
    elseif menu == 5 then
        ClearListStaminaOnly()
    elseif menu == 6 then
        GameplayMenu()
    end
end
-- ===== UNLIMITED DURATION SKILL MENU =====
function UnlimitedDurationSkillMenu()
    currentMenu = 5
    local menu = gg.choice({
        " Highlight, Spotlight Toss, Imperial Order", -- 6 Seconds
        " Flare", -- 8 Seconds
        " Typhoon", -- 15 Seconds
        " Absolute Block, Fish Bun", -- 7 Seconds
        " Gladius Wall, Head to Head", -- 5 Seconds
        " Aegis, Surprise Attack", -- 10 Seconds
        " Stable Set", -- 2 Seconds
        " Pain Killer", -- 30 Seconds
        " Intimidation", -- 12 Seconds
        " Return"
    }, 0, "• Unlimited Duration Skill Menu •")
    if menu == 1 then
        Highlight("360", "✅ Unlimited Duration Highlight, Spotlight Toss, Imperial Order!")
    elseif menu == 2 then
        Highlight("480", "✅ Unlimited Duration Flare!")
    elseif menu == 3 then
        Highlight("900", "✅ Unlimited Duration Typhoon!")
    elseif menu == 4 then
        Highlight("420", "✅ Unlimited Duration Absolute Block, Fish Bun!")
     elseif menu == 5 then
        Highlight("300", "✅ Unlimited Duration Gladius Wall, Head to Head!")
     elseif menu == 6 then
        Highlight("600", "✅ Unlimited Duration Aegis, Surprise Attack!")
     elseif menu == 7 then
        Highlight("120", "✅ Unlimited Duration Stable Set!")
    elseif menu == 8 then
        Highlight("1800", "✅ Unlimited Duration Pain Killer!")
    elseif menu == 9 then
        Highlight("720", "✅ Unlimited Duration Intimidation!")
    elseif menu == 10 then
        GameplayMenu()
    end
end
-- ===== EDIT SCORE MENU =====
function EditScoreMenu()
    currentMenu = 6
    local menu = gg.choice({
        "Set Score -> 3 : 0",
        "Set Score -> 3 : 0 ( Arena )",
        "Set Score -> 5 : 0",
        "Set Score -> 8 : 0",
        "Set Score -> 10 : 0",
        "Set Score -> 12 : 0",
        "Set Score -> 15 : 0",
        "Set Score -> 21 : 0",
        "Return"
    }, 0, "• Select Score •")    
    if menu == 1 then ModifyScore(3, 0)
    elseif menu == 2 then ModifyScore(5, 2)
    elseif menu == 3 then ModifyScore(5, 0)
    elseif menu == 4 then ModifyScore(8, 0)
    elseif menu == 5 then ModifyScore(10, 0)
    elseif menu == 6 then ModifyScore(12, 0)
    elseif menu == 7 then ModifyScore(15, 0)
    elseif menu == 8 then ModifyScore(21, 0)
    elseif menu == 9 then
        GameplayMenu()
    end
end
-- ===== MISC MENU =====
function MiscMenu()
    currentMenu = 8
    local CostumText = RecruitmentStatus and " [ ON ]" or " [ OFF ]"
    local menu = gg.choice({
        " Block Anti-Cheat", 
        " GameMaker Tools", 
        " Costum Recruitment" .. CostumText, 
        " Return"
    }, 0, "• Misc Menu •")
    if menu == 1 then
        AntiCheat()
        MiscMenu()
    elseif menu == 2 then
        Unlockdev()
        MiscMenu()
    elseif menu == 3 then
        ToggleRecruitment()
    elseif menu == 4 then
        main()
    end
end
-- ===== ANTI CHEAT FUNCTION (FIXED) =====
function AntiCheat()
    gg.setVisible(false)
    gg.toast("🔍 Patching Anti-Cheat...")
    local SEARCH_VAL = "1179403647"
    local HEX_PATCH  = "5F 00 00 F9 A8 01 80 52 48 0C 00 B9 E0 03 02 AA C0 03 5F D6"
    local OFFSETS    = {
        {offsets = {0x64abfe8, 0x7beff78, 0x5588c94, 0x41411c8, 0x55f4490, 0x5d771f8}, refine = -1},
        {offset = 0x56bb4c8, refine = -23}
    }    
    gg.clearResults()
    local oldRanges = gg.getRanges()
    gg.setRanges(gg.REGION_CODE_APP)    
    gg.searchNumber(SEARCH_VAL, gg.TYPE_DWORD)
    local count = gg.getResultsCount()    
    if count == 0 then
        gg.toast("❌ Base address not found!")
        gg.setRanges(oldRanges)
        return
    end    
    local baseResults = gg.getResults(math.min(count, 10))
    local refinedResults = {}    
    for _, res in ipairs(baseResults) do
        for _, data in ipairs(OFFSETS) do
            if data.offsets then
                for _, offset in ipairs(data.offsets) do
                    local targetAddr = res.address + offset
                    local checkVal = gg.getValues({{address = targetAddr, flags = gg.TYPE_BYTE}})[1]            
                    if checkVal and checkVal.value == data.refine then
                        table.insert(refinedResults, {address = targetAddr})
                    end
                end
            else
                local targetAddr = res.address + data.offset
                local checkVal = gg.getValues({{address = targetAddr, flags = gg.TYPE_BYTE}})[1]            
                if checkVal and checkVal.value == data.refine then
                    table.insert(refinedResults, {address = targetAddr})
                end
            end
        end
    end    
    if #refinedResults == 0 then
        gg.toast("❌ Refine failed!")
        gg.clearResults()
        gg.setRanges(oldRanges)
        return
    end 
    local function parseHexBytes(hexStr)
        local bytes = {}
        for hexByte in hexStr:gmatch("%x%x") do
            table.insert(bytes, tonumber(hexByte, 16))
        end
        return bytes
    end   
    local hexBytes = parseHexBytes(HEX_PATCH)
    local patchTable = {}   
    for _, ref in ipairs(refinedResults) do
        for idx, byteVal in ipairs(hexBytes) do
            table.insert(patchTable, {
                address = ref.address + (idx - 1),
                flags = gg.TYPE_BYTE,
                value = byteVal
            })
        end
    end   
    if #patchTable > 0 then
        gg.setValues(patchTable)
    end    
    gg.clearResults()
    gg.setRanges(oldRanges)
    gg.toast("✅ Successfully Patched Block Anti-Cheat!")
end
-- ===== GAMEMAKER TOOLS FUNCTION =====
function Unlockdev()
     gg.setVisible(false)
     gg.toast("🔍 Patching GameMaker Tools...")
     local editValue = {[1] = "53"}     
     local SEARCH_VAL = "1179403647"
     local OFFSETS = {{offset = 0x8CD105B, refine = 54}}
     gg.clearResults()
     local oldRanges = gg.getRanges()
     gg.setRanges(gg.REGION_CODE_APP)
     gg.searchNumber(SEARCH_VAL, gg.TYPE_DWORD)
     local count = gg.getResultsCount()
     if count == 0 then
          gg.toast("❌ Base address not found!")
          gg.setRanges(oldRanges)
          return
     end
     local baseResults = gg.getResults(math.min(count, 10))
     local refinedResults = {}
     for _, res in ipairs(baseResults) do
          for _, data in ipairs(OFFSETS) do
               local targetAddr = res.address + data.offset
               local checkVal = gg.getValues({{address = targetAddr, flags = gg.TYPE_BYTE}})[1]
               if checkVal and checkVal.value == data.refine then
                    table.insert(refinedResults, {address = targetAddr})
               end
          end
     end
     if #refinedResults == 0 then
          gg.toast("❌ Refine failed!")
          gg.clearResults()
          gg.setRanges(oldRanges)
          return
     end
     local editTable = {}
     for _, ref in ipairs(refinedResults) do
          table.insert(editTable, {
               address = ref.address,
               flags = gg.TYPE_BYTE,
               value = editValue[1]
          })
     end
     if #editTable > 0 then
          gg.setValues(editTable)
     end
     gg.clearResults()
     gg.setRanges(oldRanges)
     gg.toast("✅ GameMaker Tools Successfully!")
end
-- ===== DUMMY ENEMY FUNCTION =====
function ToggleDummyEnemy()
    gg.setVisible(false)
    if not dummyEnemyStatus then
        if #dummySnapshot == 0 then
            gg.toast("🔍 Patching Dummy Enemy...")
            local SEARCH_VAL = "1179403647"
            local OFFSETS = {{offset = 0x4BC3864, refine = 0}}            
            gg.clearResults()
            local oldRanges = gg.getRanges()
            gg.setRanges(gg.REGION_CODE_APP)
            gg.searchNumber(SEARCH_VAL, gg.TYPE_DWORD)
            local count = gg.getResultsCount()          
            if count == 0 then
                gg.toast("❌ Base address not found!")
                gg.setRanges(oldRanges)
                return
            end           
            local baseResults = gg.getResults(math.min(count, 10))
            local refinedResults = {}
            for _, res in ipairs(baseResults) do
                for _, data in ipairs(OFFSETS) do
                    local targetAddr = res.address + data.offset
                    local checkVal = gg.getValues({{address = targetAddr, flags = gg.TYPE_BYTE}})[1]
                    if checkVal and checkVal.value == data.refine then
                        table.insert(refinedResults, {address = targetAddr, flags = gg.TYPE_BYTE})
                    end
                end
            end       
            if #refinedResults == 0 then
                gg.toast("❌ Refine failed!")
                gg.clearResults()
                gg.setRanges(oldRanges)
                return
            end
            dummySnapshot = gg.getValues(refinedResults)
            gg.clearResults()
            gg.setRanges(oldRanges)
        end
        local editTable = {}
        for _, item in ipairs(dummySnapshot) do
            table.insert(editTable, {
                address = item.address,
                flags = item.flags,
                value = 1
            })
        end
        gg.setValues(editTable)
        dummyEnemyStatus = true
        gg.toast("✅ Dummy Enemy [ON]")
    else
        if #dummySnapshot > 0 then
            gg.setValues(dummySnapshot)
            dummyEnemyStatus = false
            gg.toast("❌ Dummy Enemy [OFF]")
        else
            gg.toast("⚠️ Value missing!")
        end
    end
end
-- ===== SKY SERVE FUNCTION =====
function ToggleSkyServe()
    gg.setVisible(false)
    if not skyServeStatus then
        if #skyServeSnapshot == 0 then
            gg.toast("🔍 Patching Sky Serve...")
            local SEARCH_VAL = "1179403647"
            local OFFSETS = {{offset = 0x955AD18, refine = 1573.12}}            
            gg.clearResults()
            local oldRanges = gg.getRanges()
            gg.setRanges(gg.REGION_CODE_APP)
            gg.searchNumber(SEARCH_VAL, gg.TYPE_DWORD)
            local count = gg.getResultsCount()            
            if count == 0 then
                gg.toast("❌ Base address not found!")
                gg.setRanges(oldRanges)
                return
            end            
            local baseResults = gg.getResults(math.min(count, 10))
            local refinedResults = {}
            for _, res in ipairs(baseResults) do
                for _, data in ipairs(OFFSETS) do
                    local targetAddr = res.address + data.offset
                    local checkVal = gg.getValues({{address = targetAddr, flags = gg.TYPE_DOUBLE}})[1]
                    if checkVal and checkVal.value == data.refine then
                        table.insert(refinedResults, {address = targetAddr, flags = gg.TYPE_DOUBLE})
                    end
                end
            end            
            if #refinedResults == 0 then
                gg.toast("❌ Refine failed!")
                gg.clearResults()
                gg.setRanges(oldRanges)
                return
            end
            skyServeSnapshot = gg.getValues(refinedResults)
            gg.clearResults()
            gg.setRanges(oldRanges)
        end
        local editTable = {}
        for _, item in ipairs(skyServeSnapshot) do
            table.insert(editTable, {
                address = item.address,
                flags = item.flags,
                value = 9999
            })
        end
        gg.setValues(editTable)
        skyServeStatus = true
        gg.toast("✅ Sky Serve [ON]")
    else
        if #skyServeSnapshot > 0 then
            gg.setValues(skyServeSnapshot)
            skyServeStatus = false
            gg.toast("❌ Sky Serve [OFF]")
        else
            gg.toast("⚠️ Value missing!")
        end
    end
end
-- ===== AUTO WIN LITE FUNCTION =====
function ToggleAutoWinLite()
    gg.setVisible(false)
    if not AutoWinStatus then
        if #AutoWinSnapshot == 0 then
            gg.toast("🔍 Patching Auto Win Lite...")
            local SEARCH_VAL = "1179403647"
            local OFFSETS = {{offset = 0x9556CE0, refine = -1}}            
            gg.clearResults()
            local oldRanges = gg.getRanges()
            gg.setRanges(gg.REGION_CODE_APP)
            gg.searchNumber(SEARCH_VAL, gg.TYPE_DWORD)
            local count = gg.getResultsCount()            
            if count == 0 then
                gg.toast("❌ Base address not found!")
                gg.setRanges(oldRanges)
                return
            end            
            local baseResults = gg.getResults(math.min(count, 10))
            local refinedResults = {}
            for _, res in ipairs(baseResults) do
                for _, data in ipairs(OFFSETS) do
                    local targetAddr = res.address + data.offset
                    local checkVal = gg.getValues({{address = targetAddr, flags = gg.TYPE_DOUBLE}})[1]
                    if checkVal and checkVal.value == data.refine then
                        table.insert(refinedResults, {address = targetAddr, flags = gg.TYPE_DOUBLE})
                    end
                end
            end            
            if #refinedResults == 0 then
                gg.toast("❌ Refine failed!")
                gg.clearResults()
                gg.setRanges(oldRanges)
                return
            end
            AutoWinSnapshot = gg.getValues(refinedResults)
            gg.clearResults()
            gg.setRanges(oldRanges)
        end
        local editTable = {}
        for _, item in ipairs(AutoWinSnapshot) do
            table.insert(editTable, {
                address = item.address,
                flags = item.flags,
                value = 0
            })
        end
        gg.setValues(editTable)
        AutoWinStatus = true
        gg.toast("✅ Auto Win Lite [ON]")
    else
        if #AutoWinSnapshot > 0 then
            gg.setValues(AutoWinSnapshot)
            AutoWinStatus = false
            gg.toast("❌ Auto Win Lite [OFF]")
        else
            gg.toast("⚠️ Value missing!")
        end
    end
end
-- ===== AUTO SERVE FUNCTION =====
function ToggleServe()
    gg.setVisible(false)
    if not ServeStatus then
        if #ServeSnapshot == 0 then
            gg.toast("🔍 Patching Sky Serve...")
            local SEARCH_VAL = "1179403647"
            local OFFSETS = {{offset = 0x9526EB8, refine = 1}}            
            gg.clearResults()
            local oldRanges = gg.getRanges()
            gg.setRanges(gg.REGION_CODE_APP)
            gg.searchNumber(SEARCH_VAL, gg.TYPE_DWORD)
            local count = gg.getResultsCount()            
            if count == 0 then
                gg.toast("❌ Base address not found!")
                gg.setRanges(oldRanges)
                return
            end            
            local baseResults = gg.getResults(math.min(count, 10))
            local refinedResults = {}
            for _, res in ipairs(baseResults) do
                for _, data in ipairs(OFFSETS) do
                    local targetAddr = res.address + data.offset
                    local checkVal = gg.getValues({{address = targetAddr, flags = gg.TYPE_DOUBLE}})[1]
                    if checkVal and checkVal.value == data.refine then
                        table.insert(refinedResults, {address = targetAddr, flags = gg.TYPE_DOUBLE})
                    end
                end
            end            
            if #refinedResults == 0 then
                gg.toast("❌ Refine failed!")
                gg.clearResults()
                gg.setRanges(oldRanges)
                return
            end
            ServeSnapshot = gg.getValues(refinedResults)
            gg.clearResults()
            gg.setRanges(oldRanges)
        end
        local editTable = {}
        for _, item in ipairs(ServeSnapshot) do
            table.insert(editTable, {
                address = item.address,
                flags = item.flags,
                value = 0
            })
        end
        gg.setValues(editTable)
        ServeStatus = true
        gg.toast("✅ Auto Serve [ON]")
    else
        if #ServeSnapshot > 0 then
            gg.setValues(ServeSnapshot)
            ServeStatus = false
            gg.toast("❌ Auto Serve [OFF]")
        else
            gg.toast("⚠️ Value missing!")
        end
    end
end
-- ===== COSTUM RECRUITMENT FUNCTION =====
function ToggleRecruitment()
    gg.setVisible(false)
    if not RecruitmentStatus then
        local input = gg.prompt(
            {"Enter Custom Recruitment Value:"}, 
            {"10"},
            {"number"}
        )
        if not input or input[1] == "" then
            gg.toast("⚠️ Input canceled!")
            return
        end
        local newValue = tonumber(input[1])
        if not newValue then
            gg.toast("❌ Input must be a valid number!")
            return
        end
        if #RecruitmentSnapshot == 0 then
            gg.toast("🔍 Patching Custom Recruitment...")
            local SEARCH_VAL = "1179403647"
            local OFFSETS = {
                {offset = 0x9564D88, refine = 10},
                {offset = 0x9565008, refine = 10}
            }                       
            gg.clearResults()
            local oldRanges = gg.getRanges()
            gg.setRanges(gg.REGION_CODE_APP)
            gg.searchNumber(SEARCH_VAL, gg.TYPE_DWORD)
            local count = gg.getResultsCount()            
            if count == 0 then
                gg.toast("❌ Base address not found!")
                gg.setRanges(oldRanges)
                return
            end            
            local baseResults = gg.getResults(math.min(count, 10))
            local refinedResults = {}
            for _, res in ipairs(baseResults) do
                for _, data in ipairs(OFFSETS) do
                    local targetAddr = res.address + data.offset
                    local checkVal = gg.getValues({{address = targetAddr, flags = gg.TYPE_DOUBLE}})[1]
                    if checkVal and checkVal.value == data.refine then
                        table.insert(refinedResults, {address = targetAddr, flags = gg.TYPE_DOUBLE})
                    end
                end
            end            
            if #refinedResults == 0 then
                gg.toast("❌ Refine failed!")
                gg.clearResults()
                gg.setRanges(oldRanges)
                return
            end
            RecruitmentSnapshot = gg.getValues(refinedResults)
            gg.clearResults()
            gg.setRanges(oldRanges)
        end
        local editTable = {}
        for _, item in ipairs(RecruitmentSnapshot) do
            table.insert(editTable, {
                address = item.address,
                flags = item.flags,
                value = newValue
            })
        end     
        gg.setValues(editTable)
        RecruitmentStatus = true
        gg.toast("✅ Custom Recruitment [ON]")
    else
        if #RecruitmentSnapshot > 0 then
            gg.setValues(RecruitmentSnapshot)
            RecruitmentStatus = false
            gg.toast("❌ Custom Recruitment [OFF]")
        else
            gg.toast("⚠️ Value missing!")
        end
    end
end
-- ===== CURRENCY HACK =====
function MenuCurrency() 
    local input = gg.prompt({
        "▶ Input Credit",
        "▶ Input Exp",
        "▶ Input V-Point",
        "▶ Input Blue Flame",
    }, {}, {"number", "number", "number", "number"})       
    if not input then
        gg.toast("❌ Canceled")
        return
    end
    local RefineCredit = input[1]
    local RefineExp = input[2]
    local RefineVpoint = input[3]
    local RefineBlueFlame = input[4]
    local newValue = 999999999
    local patterns = {
        {
            name = "Currency",
            search = "h C3 E2 01 00 C4 E2 01 00",
            refine = "-61",
            offsets = {0, -0x10, -0x30, -0x40},
            values = {
                {name = "Credit", refine = RefineCredit, active = (RefineCredit ~= nil and RefineCredit ~= 0)},
                {name = "Exp", refine = RefineExp, active = (RefineExp ~= nil and RefineExp ~= 0)},
                {name = "V-Point", refine = RefineVpoint, active = (RefineVpoint ~= nil and RefineVpoint ~= 0)},
                {name = "Blue Flame", refine = RefineBlueFlame, active = (RefineBlueFlame ~= nil and RefineBlueFlame ~= 0)}
            }
        }
    }    
    local allResults = {}
    local totalChanged = 0
    for i, pattern in ipairs(patterns) do
        local hasActiveValue = false
        for _, valueItem in ipairs(pattern.values) do
            if valueItem.active then
                hasActiveValue = true
                break
            end
        end
        if hasActiveValue then
            gg.setRanges(gg.REGION_C_ALLOC)
            gg.clearResults()
            gg.searchNumber(pattern.search, gg.TYPE_BYTE)
            local count = gg.getResultsCount()
            if count == 0 then
                gg.toast("pattern not found!")
                return
            end            
            gg.refineNumber(pattern.refine, gg.TYPE_BYTE)
            count = gg.getResultsCount()
            if count == 0 then
                gg.toast("refine value not found!")
                return
            end            
            local results = gg.getResults(count)
            local pointerList = {}
            for _, v in ipairs(results) do
                pointerList[#pointerList + 1] = {
                    address = v.address - 0x8,
                    flags = gg.TYPE_QWORD
                }
            end     
            gg.loadResults(pointerList)
            local readPtr = gg.getValues(pointerList)
            local finalAddress = {}
            for _, v in ipairs(readPtr) do
                if v.value and v.value ~= 0 then
                    finalAddress[#finalAddress + 1] = {
                        address = v.value,
                        flags = gg.TYPE_DOUBLE
                    }
                end
            end         
            if #finalAddress == 0 then
                gg.toast("pointer not found!")
                return
            end
            local offsetAddress = {}
            for _, v in ipairs(finalAddress) do
                for _, offset in ipairs(pattern.offsets) do
                    offsetAddress[#offsetAddress + 1] = {
                        address = v.address + offset,
                        flags = gg.TYPE_DOUBLE
                    }
                end
            end
            for _, valueItem in ipairs(pattern.values) do
                if valueItem.active then
                    gg.clearResults()
                    gg.loadResults(offsetAddress)
                    gg.refineNumber(valueItem.refine, gg.TYPE_DOUBLE)
                    local countResult = gg.getResultsCount()
                    if countResult == 0 then
                        gg.toast("value not found!")
                        return
                    end               
                    local valueResults = gg.getResults(countResult)
                    for _, v in ipairs(valueResults) do
                        allResults[#allResults + 1] = {
                            address = v.address,
                            value = newValue,
                            flags = gg.TYPE_DOUBLE
                        }
                        totalChanged = totalChanged + 1
                    end
                end
            end
        end
    end
    if #allResults == 0 then
        gg.toast(" No results to apply!")
        return
    end  
    gg.setValues(allResults)
    gg.clearResults()
    gg.toast(" Unlimited All Currency Active!")
    gg.alert(" Go to the In-Game Shop and then return to the Main Menu")
end

local staminaSavedItems = {}
-- ===== CLEAR LIST ITEM =====
function ClearListStaminaOnly()
    if #staminaSavedItems == 0 then
        gg.toast("⚠️ No Stamina items found in the saved list!")
        return
    end
    for i, v in ipairs(staminaSavedItems) do
        v.freeze = false
    end
    gg.addListItems(staminaSavedItems)
    gg.removeListItems(staminaSavedItems)
    staminaSavedItems = {}
    gg.toast("🗑️ Stamina list cleared successfully!")
end
-- ===== UNLIMITED STAMINA =====
function UnlimitedStaminaTournament(targetValue)
    gg.toast("🔍 Searching Base...")
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.clearResults()   
    gg.searchNumber("h B1 0B 02 00 B2 0B 02 00", gg.TYPE_BYTE)
    if gg.getResultsCount() == 0 then
        gg.alert("❌ Base address not found!")
        return
    end
    gg.refineNumber("-79", gg.TYPE_BYTE)
    if gg.getResultsCount() == 0 then
        return
    end
    local results = gg.getResults(gg.getResultsCount())
    local pointerList = {}
    for _, v in ipairs(results) do
        pointerList[#pointerList + 1] = {
            address = v.address - 0x8,
            flags   = gg.TYPE_QWORD
        }
    end
    gg.clearResults()
    local readPtr = gg.getValues(pointerList)
    local finalAddress = {}
    for _, v in ipairs(readPtr) do
        if v.value and v.value ~= 0 then
            finalAddress[#finalAddress + 1] = {
                address = v.value,
                flags   = gg.TYPE_DOUBLE
            }
        end
    end
    if #finalAddress == 0 then
        gg.alert("❌ Invalid pointer!")
        return
    end
    gg.clearResults()
    gg.loadResults(finalAddress)
    gg.refineNumber(tostring(targetValue), gg.TYPE_DOUBLE)   
    local count = gg.getResultsCount()
    if count == 0 then
        gg.toast("❌ Value " .. targetValue .. " not found!")
        return
    end
    local staminaResults = gg.getResults(count)
    for i, v in ipairs(staminaResults) do
        staminaResults[i].value = tostring(targetValue)
        staminaResults[i].freeze = true
    end    
    gg.addListItems(staminaResults)
    gg.setValues(staminaResults)
    for _, item in ipairs(staminaResults) do
        staminaSavedItems[#staminaSavedItems + 1] = item
    end    
    gg.clearResults()
    gg.toast("⚡ Unlimited Stamina Activated!")
end

function Highlight(searchValue, toastMessage)
    gg.toast("🔍 Searching Base...")
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.clearResults()   
    gg.searchNumber("h 04 E8 01 00 05 E8 01 00", gg.TYPE_BYTE)   
    if gg.getResultsCount() == 0 then
        gg.alert("❌ Base address not found!")
        return
    end
    gg.refineNumber("4", gg.TYPE_BYTE)
    if gg.getResultsCount() == 0 then
        return
    end
    local results = gg.getResults(gg.getResultsCount())
    local pointerList = {}
    for _, v in ipairs(results) do
        pointerList[#pointerList + 1] = {
            address = v.address - 0x8,
            flags   = gg.TYPE_QWORD
        }
    end
    gg.clearResults()
    local readPtr = gg.getValues(pointerList)
    local finalAddress = {}
    for _, v in ipairs(readPtr) do
        if v.value and v.value ~= 0 then
            finalAddress[#finalAddress + 1] = {
                address = v.value,
                flags   = gg.TYPE_DOUBLE
            }
        end
    end
    if #finalAddress == 0 then
        gg.alert("❌ Invalid pointer!")
        return
    end
    gg.loadResults(finalAddress)
    gg.refineNumber(searchValue, gg.TYPE_DOUBLE)
    local count = gg.getResultsCount()
    if count == 0 then
        return
    end
    local highlightResults = gg.getResults(count)
    local editList = {}
    for i, v in ipairs(highlightResults) do
        editList[#editList + 1] = {
            address = v.address,
            flags   = gg.TYPE_DOUBLE,
            value   = 999999999
        }
    end
    gg.setValues(editList)
    gg.clearResults()
    gg.toast(toastMessage)
end
-- ===== AUTOMATIC HIDE UID FUNCTION =====
function HideUID()
    gg.setVisible(false)
    local oldRanges = gg.getRanges()
    gg.setRanges(gg.REGION_CODE_APP)
    gg.clearResults()
    gg.searchNumber("1179403647", gg.TYPE_DWORD)   
    local count = gg.getResultsCount()   
    if count == 0 then
        gg.toast("⚠️ Base UID address not found!")
        gg.setRanges(oldRanges)
        return
    end        
    local results = gg.getResults(count)
    local offsetsToEdit = {
        {offset = 0x2F5FF10, target = 1426078240},
        {offset = 0x2F5FF30, target = 1853182720},
        {offset = 0x2F69D64, target = 813375520}
    }
    local successCount = 0
    for _, item in ipairs(offsetsToEdit) do
        local refined = hiddenRefine(results, item.offset, item.target, gg.TYPE_DWORD)
        if refined and #refined > 0 then
            local edits = {}
            for _, v in ipairs(refined) do
                table.insert(edits, {
                    address = v.address,
                    flags = gg.TYPE_DWORD,
                    value = 0
                })
            end
            gg.setValues(edits)
            successCount = successCount + 1
        end
    end    
    gg.clearResults()
    gg.setRanges(oldRanges)    
    if successCount > 0 then
        gg.toast("✅ Hide UID Applied & Memory Ranges Restored!")
    else
        gg.toast("⚠️ Refine UID failed / memory structure mismatch!")
    end
end
-- ===== CORE SCORE HACK =====
local savedBaseResults = nil
function GetBaseResults()
    if savedBaseResults == nil then
        gg.setRanges(gg.REGION_C_ALLOC)
        gg.clearResults()
        gg.searchNumber("795364", gg.TYPE_DWORD)
        local count = gg.getResultsCount()
        if count == 0 then
            gg.toast("❌ Base value not found!")
            return nil
        end
        savedBaseResults = gg.getResults(count)
        gg.clearResults()
    end
    return savedBaseResults
end

function ModifyScore(myValue, enemyValue)
    local baseResults = GetBaseResults()
    if not baseResults then return end 
    local checkList1 = {}
    local myCheckList = {}
    local enemyCheckList = {}
    for i, v in ipairs(baseResults) do
        checkList1[i] = { address = v.address - 0x2E0, flags = gg.TYPE_DOUBLE }
        if myValue ~= nil then
            myCheckList[i] = { address = v.address + 0x90, flags = gg.TYPE_DOUBLE }
        end
        if enemyValue ~= nil then
            enemyCheckList[i] = { address = v.address + 0x80, flags = gg.TYPE_DOUBLE }
        end
    end
    checkList1 = gg.getValues(checkList1)
    if myValue ~= nil then myCheckList = gg.getValues(myCheckList) end
    if enemyValue ~= nil then enemyCheckList = gg.getValues(enemyCheckList) end
    local targetsToEdit = {}
    for i = 1, #baseResults do
        if checkList1[i] and checkList1[i].value == -4 then
            if myValue ~= nil then
                table.insert(targetsToEdit, {
                    address = myCheckList[i].address,
                    flags = gg.TYPE_DOUBLE,
                    value = myValue,
                    freeze = true
                })
            end
            if enemyValue ~= nil then
                table.insert(targetsToEdit, {
                    address = enemyCheckList[i].address,
                    flags = gg.TYPE_DOUBLE,
                    value = enemyValue,
                    freeze = true
                })
            end
        end
    end
    if #targetsToEdit == 0 then
        gg.toast("❌ No matching structure found!")
    else
        gg.setValues(targetsToEdit)
        gg.addListItems(targetsToEdit)
        if myValue ~= nil and enemyValue ~= nil then
            gg.toast("✅ Set Score " .. myValue .. " : " .. enemyValue)
        elseif myValue ~= nil then
            gg.toast("✅ Freeze Team Score")
        else
            gg.toast("✅ Freeze Enemy Score")
        end
    end
end
-- ===== VOLLEYBALL SKIN HACK =====
local VPSkinMap = {
    ["1"] = "25", ["2"] = "26", ["3"] = "7", ["4"] = "24", ["5"] = "23",
    ["6"] = "20", ["7"] = "8", ["8"] = "22", ["9"] = "21", ["10"] = "19",
    ["11"] = "18", ["12"] = "17", ["13"] = "16", ["14"] = "13", ["15"] = "12",
    ["16"] = "27", ["17"] = "29", ["18"] = "30", ["19"] = "32", ["20"] = "33",
    ["21"] = "34", ["22"] = "35", ["23"] = "36", ["24"] = "37", ["25"] = "38",
    ["26"] = "39", ["27"] = "40", ["28"] = "41", ["29"] = "42", ["30"] = "43",
    ["31"] = "44", ["32"] = "45", ["33"] = "46", ["34"] = "47", ["35"] = "48",
    ["36"] = "49", ["37"] = "50", ["38"] = "51", ["39"] = "52"
}
local volleyballCache = nil
function MenuVolleyballSkin()
    gg.setVisible(false)
    gg.alert([[
⚽ Select Volleyball Skin ⚽
1. Beach Ball
2. Watermelon Beach Ball
3. Nishikawa Ball
4. Full Moon
5. High Noon
6. Piggy Bank Ball
7. Crimson Valentia Ball
8. Trick Ball
9. Pinata Ball
10. Bouquet Volleyball
11. Rise Volleyball
12. Christmas Ball
13. Winter Snow Ball
14. Master Ball
15. Seonrim High School Ball
16. Seaweed Ball
17. Silver Balloon Ball
18. Blue Balloon Ball
19. Black Spider Ball
20. Jack o lantern Ball
21. Ball Neon
22. Ball Venom
23. Jingle Bell Ball
24. Star Snow Ball
25. Ball Nishikawa Black
26. Mother of pearl Ball
27. 2026 Lucky Pouch Ball
28. Graffiti King
29. Wind Spiral Ball
30. Prism Rainbow Ball
31. 8th Anniversary Commemorative Ball
32. Mystic Aurora Ball
33. Tumbleweed Ball
34. Cactus Ball
35. Coconut Ball
36. Hanra Ball
37. Viola Ball
38. NTC Exclusive Ball
39. Gitae’s Favorite Ball
    ]])
    local input = gg.prompt({"👑 Select Volleyball Skin 👑 [ 1 ~ 39 ]"}, {}, {"number"})
    if not input or not input[1] then
        gg.toast("❌ Canceled")
        return
    end
    local skinID = tostring(input[1])
    if not VPSkinMap[skinID] then
        gg.toast("❌ Invalid selection!")
        return
    end
    local skinValue = tonumber(VPSkinMap[skinID])
    if not volleyballCache then
        gg.clearResults()        
        gg.setRanges(gg.REGION_C_ALLOC)
        gg.searchNumber("-795364", gg.TYPE_DWORD)
        local results = gg.getResults(-1)
        if #results == 0 then
            return
        end
        local refineCheck = {}
        for _, v in ipairs(results) do
            table.insert(refineCheck, {address = v.address + 0x150, flags = gg.TYPE_DOUBLE})
        end
        refineCheck = gg.getValues(refineCheck)
        local refined = {}
        for _, v in ipairs(refineCheck) do
            if tonumber(v.value) == -4 then
                table.insert(refined, {address = v.address + 0x160})
            end
        end
        if #refined == 0 then
            return
        end
        volleyballCache = refined
    end
    local edits = {}
    for _, v in ipairs(volleyballCache) do
        table.insert(edits, {
            address = v.address,
            flags = gg.TYPE_DOUBLE,
            value = skinValue,
            freeze = true
        })
    end
    gg.addListItems(edits)
    gg.clearResults()
    gg.toast("⚽ Volleyball Skin Applied!")
end
-- ===== MAP IN GAME HACK =====
local BackgroundMap = {
    ["1"] = "0", 
    ["2"] = "1",
    ["3"] = "2", 
    ["4"] = "3", 
    ["5"] = "4",
    ["6"] = "5", 
    ["7"] = "6", 
    ["8"] = "7", 
    ["9"] = "8", 
    ["10"] = "9",
    ["11"] = "10", 
    ["12"] = "11",
    ["13"] = "12",
    ["14"] = "13",
    ["15"] = "15",
    ["16"] = "16", 
    ["17"] = "17", 
    ["18"] = "19", 
    ["19"] = "20",
    ["20"] = "21",
    ["21"] = "22",
    ["22"] = "23",
    ["23"] = "24",
    ["24"] = "25", 
    ["25"] = "26", 
    ["26"] = "27", 
    ["27"] = "28", 
    ["28"] = "29", 
    ["29"] = "30"
}
local backgroundcache = nil
function MenuBackground()
    gg.setVisible(false)
    gg.alert([[
🌆 Select Map in Game 🌆
1. Regional Tournament Arena
2. Regional Tournament Arena
3. National Tournament Arena
4. School Gym
5. Summer Splash
6. void:MAP_PRO_TURNAMENT
7. Superstar Challenge
8. Valentia Spikes Court
9. void:MAP_DARK_NISHIKAWA
10. Volleyball Colosseum
11. Seonrim High
12. Rockwell Winter Camp
13. Rockwell Winter Camp Gym
14. Dark City
15. Phantom League
16. Azure Dragon Festival
17. Phantom League (Old) 
18. Nightmare Arena
19. Chromakey
20. Phantom League Performance Hall
21. Phantom League Performance Hall
22. Outlaw Frontier
23. Outlaw Frontier
24. void:MAP_PARK
25. void:MAP_PARK_SUNSET
26. void:MAP_PARK_SUNSET
27. School Gym
28. Soaring Gym
29. void:MAP_NATIONAL_NO_CROWD
    ]])
    local input = gg.prompt({"👑 Select Map in Game 👑 [ 1 ~ 29 ]"}, {}, {"number"})
    if not input or not input[1] then
        gg.toast("❌ Canceled")
        return
    end
    local skinID = tostring(input[1])
    if not BackgroundMap[skinID] then
        gg.toast("❌ Invalid selection!")
        return
    end
    local skinValue = tonumber(BackgroundMap[skinID])
    if not backgroundcache then
        gg.setRanges(gg.REGION_C_ALLOC)
        gg.clearResults()        
        gg.searchNumber("795364", gg.TYPE_DWORD)
        local results = gg.getResults(-1)
        if #results == 0 then
            return
        end
        local refineCheck = {}
        for _, v in ipairs(results) do
            table.insert(refineCheck, {address = v.address - 0x2E0, flags = gg.TYPE_DOUBLE})
        end
        refineCheck = gg.getValues(refineCheck)
        local refined = {}
        for _, v in ipairs(refineCheck) do
            if tonumber(v.value) == -4 then
                table.insert(refined, {address = v.address + 0x390})
            end
        end
        if #refined == 0 then
            gg.toast("⚠️ Refine failed!")
            return
        end
        backgroundcache = refined
    end
    local edits = {}
    for _, v in ipairs(backgroundcache) do
        table.insert(edits, {
            address = v.address,
            flags = gg.TYPE_DOUBLE,
            value = skinValue,
            freeze = true
        })
    end
    gg.addListItems(edits)
    gg.clearResults()
    gg.toast("🌆 Map in Game Applied!")
end

function HighFov() 
    local input = gg.prompt(
        {"Enter Field of View [8;21]"},
        {"8"},
        {"number"}
    )
    if not input or not input[1] then
        gg.toast("❌ Cancelled")
        return
    end
    local editValue = tonumber(input[1])
    if not editValue or editValue < 8 or editValue > 21 then
        return
    end
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber("h B3 31 02 00 B4 31 02 00", gg.TYPE_BYTE)   
    local count = gg.getResultsCount()
    if count == 0 then
        gg.toast("❌ Initial pattern not found")
        return
    end
    gg.refineNumber("-77", gg.TYPE_BYTE)
    count = gg.getResultsCount()
    if count == 0 then
        gg.toast("❌ Refine failed")
        return
    end
    local results = gg.getResults(count)
    local OFFSET = 0x8
    local pointerList = {}
    for _, v in ipairs(results) do
        table.insert(pointerList, {
            address = v.address - OFFSET,
            flags = gg.TYPE_QWORD 
        })
    end
    local readPtr = gg.getValues(pointerList)
    local targetList = {}
    for _, v in ipairs(readPtr) do
        if v.value and tonumber(v.value) and v.value > 0 then
            table.insert(targetList, {
                address = v.value,
                flags = gg.TYPE_DOUBLE
            })
        end
    end
    if #targetList == 0 then
        gg.toast("❌ Invalid pointer target")
        return
    end
    gg.loadResults(targetList)
    gg.refineNumber("8~21", gg.TYPE_DOUBLE)
    count = gg.getResultsCount()
    if count == 0 then
        gg.toast("❌ Refine failed")
        return
    end
    local finalResults = gg.getResults(count)
    local editList = {}
    for _, v in ipairs(finalResults) do
        table.insert(editList, {
            address = v.address,
            flags = gg.TYPE_DOUBLE,
            value = editValue
        })
    end
    gg.setValues(editList)
    gg.clearResults()
    gg.toast("✅ High Field of View!")
end

function HeightChar()
  local prompt = gg.prompt(
    {"Enter Height Character"},
    {},
    {"number"}
  )
  if not prompt then
    gg.toast("Process cancelled!")
    return
  end
  local EDIT_VALUE = prompt[1]
  gg.clearResults()
  gg.setRanges(gg.REGION_C_ALLOC)
  gg.searchNumber("h 41 F8 01 00 42 F8 01 00", gg.TYPE_BYTE)
  local count = gg.getResultsCount()
  if count == 0 then
    gg.toast("Base not found!")
    return
  end
  gg.refineNumber("65", gg.TYPE_BYTE)
  count = gg.getResultsCount()
  if count == 0 then
    gg.toast("Value not found!")
    return
  end
  local results = gg.getResults(count)
  local pointerList = {}
  for _, v in ipairs(results) do
    table.insert(pointerList, {
      address = v.address - 0x8,
      flags = gg.TYPE_QWORD
    })
  end
  local readPtr = gg.getValues(pointerList)
  local finalAddress = {}
  for _, v in ipairs(readPtr) do
    if v.value ~= 0 then
      table.insert(finalAddress, {
        address = v.value,
        flags = gg.TYPE_DOUBLE
      })
    end
  end
  if #finalAddress == 0 then
    gg.toast("Null or empty pointers!")
    return
  end
  gg.clearResults()
  gg.loadResults(finalAddress)
  gg.refineNumber("87~280", gg.TYPE_DOUBLE)
  count = gg.getResultsCount()
  if count == 0 then
    gg.toast("Value not found!")
    return
  end
  local finalResults = gg.getResults(count)
  for _, v in ipairs(finalResults) do
    v.value = EDIT_VALUE
    v.flags = gg.TYPE_DOUBLE
  end
  gg.setValues(finalResults)
  gg.clearResults()
  gg.toast("✅ Change Height All Character")
end

function TierMastery()
    local editMenu = gg.choice({
        " Champion",
        " ????"
    }, 0, "Select Tier Mastery")
    if editMenu == nil then
        return
    end   
    EDIT_VALUE = editMenu + 3
    ExecuteScript2()
end

function ExecuteScript2()
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber("h 34 15 02 00 35 15 02 00", gg.TYPE_BYTE)
    local count = gg.getResultsCount()
    if count == 0 then
        gg.toast(" Base not found")
        return
    end
    gg.refineNumber("52", gg.TYPE_BYTE)
    count = gg.getResultsCount()
    if count == 0 then
        gg.toast(" Refine not found")
        return
    end
    local results = gg.getResults(count)
    local pointerList = {}
    for _, v in ipairs(results) do
        table.insert(pointerList, {
            address = v.address - 0x8,
            flags = gg.TYPE_QWORD
        })
    end
    local readPtr = gg.getValues(pointerList)
    local editList = {}
    for _, v in ipairs(readPtr) do
        if v.value ~= 0 then
            table.insert(editList, {
                address = v.value,
                flags = gg.TYPE_DOUBLE,
                value = EDIT_VALUE
            })
        end
    end
    if #editList == 0 then
        gg.toast(" Invalid pointer")
        return
    end
    gg.setValues(editList)
    gg.clearResults()
    gg.toast("✅ Tier Mastery Done")
end
-- ================= DATA LIST =================
local listTargetChar = {
    {name = "Siwoo", id = 1},
    {name = "Nishikawa (Ori)", id = 98},
    {name = "Nishikawa (Old)", id = 99},
    {name = "Nishikawa_SkinBlack", id = 164},
    {name = "Ryuhyeon", id = 225},
    {name = "Nishikawa_SkinHighschool_ForEventAI", id = 248},
    {name = "Lucas", id = 284},
    {name = "AwakenSiwoo_GetWeaker", id = 296},
    {name = "Raul", id = 324},
    {name = "AwakenSiwoo_Highlight", id = 325},
    {name = "SpikerSara", id = 351},
    {name = "King_Raul", id = 352}
}

local listTumbalPlayer = {
    {name = "Yongsub", id = 10},
    {name = "Heesung", id = 19},
    {name = "Jaehyun", id = 30},
    {name = "AhYeon", id = 31},
    {name = "Yoonseok", id = 39},
    {name = "Lisia", id = 40},
    {name = "Atis", id = 44},
    {name = "Oasis", id = 50},
    {name = "Minjun", id = 65},
    {name = "Sohee", id = 95},
    {name = "Yamadera", id = 96},
    {name = "Nishikawa", id = 98},
    {name = "Viola", id = 157},
    {name = "Leon", id = 158},
    {name = "Isabel", id = 159},
    {name = "SangHyeon", id = 160},
    {name = "NN", id = 161},
    {name = "Roberto", id = 163},
    {name = "Seolhwa", id = 200},
    {name = "Hongsi", id = 212},
    {name = "Sodam", id = 215},
    {name = "Hanra", id = 218},
    {name = "Muyeong", id = 221},
    {name = "Ryuhyeon", id = 225},
    {name = "Dave", id = 228},
    {name = "Mike", id = 229},
    {name = "Sara", id = 230},
    {name = "Tania", id = 231},
    {name = "Clyde", id = 232},
    {name = "Jenny", id = 251},
    {name = "Ellio", id = 252},
    {name = "Hari", id = 282},
    {name = "Crow", id = 283},
    {name = "Lucas", id = 284},
    {name = "Zero", id = 286},
    {name = "Claire", id = 322},
    {name = "Sif", id = 323},
    {name = "Raul", id = 324},
    {name = "Iris", id = 349},
    {name = "Yuri", id = 350},
    {name = "SpikerSara", id = 351},
    {name = "Kang Sejin", id = 386},
    {name = "Han Gitae", id = 387},
    {name = "Seo Yuna", id = 388}
}

function ChangeMastery()
    local targetMenuText = {}
    for _, v in ipairs(listTargetChar) do
        table.insert(targetMenuText, "▶ " .. v.name)
    end    
    local selTarget = gg.multiChoice(targetMenuText, nil, "• Select Target Character (Multiple Allowed) •")
    if selTarget == nil then return end  
    local chosenTargets = {}
    for idx, isSelected in pairs(selTarget) do
        if isSelected then
            table.insert(chosenTargets, listTargetChar[idx])
        end
    end
    if #chosenTargets == 0 then
        gg.toast("⚠️ No targets selected!")
        return
    end
    local tumbalMenuText = {}
    for _, v in ipairs(listTumbalPlayer) do
        table.insert(tumbalMenuText, "▶ " .. v.name)
    end
    local selTumbal = gg.multiChoice(tumbalMenuText, nil, "• Select Player (Total Needed: " .. #chosenTargets .. ") •")
    if selTumbal == nil then return end
    local chosenTumbals = {}
    for idx, isSelected in pairs(selTumbal) do
        if isSelected then
            table.insert(chosenTumbals, listTumbalPlayer[idx])
        end
    end
    if #chosenTumbals == 0 then
        gg.toast("⚠️ No sacrifices selected!")
        return
    end
    local countTarget = #chosenTargets
    local countTumbal = #chosenTumbals
    local loopCount = math.min(countTarget, countTumbal)
    local reportText = "📊 Process Report:\n\n"
    reportText = reportText .. "✅ To Be Processed (" .. loopCount .. " Characters):\n"
    for i = 1, loopCount do
        reportText = reportText .. string.format(" %d. %s ➔ %s\n", i, chosenTumbals[i].name, chosenTargets[i].name)
    end
    if countTumbal < countTarget then
        reportText = reportText .. "\n⚠️ Target Not Changed (Not Enough Sacrifices):\n"
        for i = loopCount + 1, countTarget do
            reportText = reportText .. " • " .. chosenTargets[i].name .. "\n"
        end
    elseif countTumbal > countTarget then
        reportText = reportText .. "\n⚠️ Sacrifice Canceled (Excess Sacrifices):\n"
        for i = loopCount + 1, countTumbal do
            reportText = reportText .. " • " .. chosenTumbals[i].name .. "\n"
        end
    end
    gg.alert(reportText, "Proceed Execution")
    local successCount = 0
    for i = 1, loopCount do
        local tumbal = chosenTumbals[i]
        local target = chosenTargets[i]
        gg.toast(string.format("Changing [%d/%d]: %s ➔ %s...", i, loopCount, tumbal.name, target.name))        
        local isSuccess = ProcessSingleMastery(tumbal.id, target.id)
        if isSuccess then
            successCount = successCount + 1
        end
    end
    gg.clearResults()
    gg.alert(string.format("✅ Finished!\nSuccessfully processed %d out of %d character pair(s).", successCount, loopCount))
end

function ProcessSingleMastery(tumbalID, targetID)
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)    
    gg.searchNumber("h E5 0E 02 00 E6 0E 02 00", gg.TYPE_BYTE)
    local count = gg.getResultsCount()
    if count == 0 then return false end
    gg.refineNumber("-27", gg.TYPE_BYTE)
    count = gg.getResultsCount()
    if count == 0 then return false end
    local results = gg.getResults(count)
    local pointerList = {}
    for _, v in ipairs(results) do
        table.insert(pointerList, {
            address = v.address - 0x8,
            flags = gg.TYPE_QWORD
        })
    end
    gg.loadResults(pointerList)
    local readPtr = gg.getValues(pointerList)
    local finalAddress = {}
    for _, v in ipairs(readPtr) do
        if v.value ~= 0 then
            table.insert(finalAddress, {
                address = v.value,
                flags = gg.TYPE_DOUBLE
            })
        end
    end
    if #finalAddress == 0 then return false end
    gg.clearResults()
    gg.loadResults(finalAddress)
    gg.refineNumber(tostring(tumbalID), gg.TYPE_DOUBLE)
    count = gg.getResultsCount()
    if count == 0 then return false end
    local resultsPlayer = gg.getResults(count)
    local offsetList = {}
    for _, v in ipairs(resultsPlayer) do
        table.insert(offsetList, {
            address = v.address + 0x3C,
            flags = gg.TYPE_DWORD
        })
    end
    gg.loadResults(offsetList)
    gg.refineNumber("6", gg.TYPE_DWORD)
    count = gg.getResultsCount()
    if count == 0 then
        gg.clearResults()
        return false
    end
    local resultsDword = gg.getResults(count)
    local doubleOffsetList = {}
    for _, v in ipairs(resultsDword) do
        table.insert(doubleOffsetList, {
            address = v.address - 0x3C,
            flags = gg.TYPE_DOUBLE
        })
    end
    gg.loadResults(doubleOffsetList)
    local finalResults = gg.getResults(#doubleOffsetList)
    local editList = {}
    for _, v in ipairs(finalResults) do
        table.insert(editList, {
            address = v.address,
            flags = gg.TYPE_DOUBLE,
            value = targetID
        })
    end
    gg.setValues(editList)
    gg.clearResults()
    return true
end
-- ===== PLAYER DATABASE =====
local listMB = {
    {name = "Ohjun", id = 3},
    {name = "Hyunsoo", id = 6},
    {name = "Hanadu", id = 8},
    {name = "Eunsup", id = 12},
    {name = "KwonMin", id = 15},
    {name = "Heeseong", id = 19},
    {name = "Isijak", id = 20},
    {name = "Squat", id = 23},
    {name = "Pureum", id = 26},
    {name = "Yeongseok", id = 29},
    {name = "2KNO3", id = 32},
    {name = "Ilbong", id = 38},
    {name = "Sivir", id = 41},
    {name = "Atis", id = 44},
    {name = "Kevin", id = 48},
    {name = "Giant Big", id = 52},
    {name = "Donggeon", id = 55},
    {name = "Min Gyu", id = 58},
    {name = "Uiseong", id = 61},
    {name = "Hyukjin", id = 64},
    {name = "Yongbi", id = 67},
    {name = "Jiho", id = 74},
    {name = "Dabin", id = 76},
    {name = "Heontae", id = 78},
    {name = "Seongjwa", id = 81},
    {name = "Soin", id = 84},
    {name = "Eun Seong", id = 87},
    {name = "Seung Seon", id = 90},
    {name = "Mizuho", id = 93},
    {name = "Yamadera", id = 96},
    {name = "Park Cheetah", id = 103},
    {name = "Nae Gi", id = 106},
    {name = "Taichi", id = 108},
    {name = "Jangmi", id = 113},
    {name = "Sanghyeon", id = 160},
    {name = "Roberto", id = 163},
    {name = "Dupal", id = 166},
    {name = "Oslo", id = 169},
    {name = "Verde", id = 171},
    {name = "Marco", id = 173},
    {name = "Ricardo", id = 176},
    {name = "Alessia", id = 178},
    {name = "Giacomo", id = 183},
    {name = "Piano", id = 186},
    {name = "Lucius", id = 189},
    {name = "Leopoldo", id = 192},
    {name = "Alessia", id = 196},
    {name = "Taeho", id = 202},
    {name = "Jihwi", id = 206},
    {name = "Daewoong", id = 213},
    {name = "Dalji", id = 216},
    {name = "Hanra", id = 218},
    {name = "Donggwan", id = 223},
    {name = "Mike", id = 229},
    {name = "Clyde", id = 232},
    {name = "Liam", id = 233},
    {name = "Gavin", id = 239},
    {name = "Kazuki", id = 249},
    {name = "Milo Zern", id = 253},
    {name = "Jure", id = 258},
    {name = "Elva", id = 261},
    {name = "Oren Bel", id = 262},
    {name = "Theo", id = 266},
    {name = "Alessia", id = 269},
    {name = "Tomat", id = 271},
    {name = "Cappuccino", id = 274},
    {name = "Barolo", id = 277},
    {name = "Cinnamiel", id = 280},
    {name = "Hari", id = 282},
    {name = "Crow", id = 283},
    {name = "Minerva", id = 288},
    {name = "Dante", id = 293},
    {name = "Bruno", id = 297},
    {name = "Enrico", id = 302},
    {name = "Eustachio", id = 303},
    {name = "Burrata", id = 308},
    {name = "Eustachio", id = 310},
    {name = "Kim Jisam", id = 316},
    {name = "Claire", id = 322},
    {name = "Valerio", id = 326},
    {name = "Obsidian", id = 328},
    {name = "Granita", id = 340},
    {name = "Calzone", id = 343},
    {name = "Cacciatore", id = 346},
    {name = "Yuri", id = 350},
    {name = "Mia", id = 358},
    {name = "Shane", id = 366},
    {name = "Walker", id = 368},
    {name = "Saya", id = 374},
    {name = "Han Gitae", id = 387},
    {name = "Jaewon Lee", id = 400},
    {name = "Seohee Pyeon", id = 402},
    {name = "Minseok Song", id = 405},
}

local listSE = {
    {name = "Jaeho", id = 2},
    {name = "Victor", id = 4},
    {name = "Jaehyun", id = 7},
    {name = "Jeongbin", id = 9},
    {name = "Sehwan", id = 11},
    {name = "KimMin", id = 14},
    {name = "Proteo", id = 22},
    {name = "Sin Bada", id = 25},
    {name = "Jaewook", id = 28},
    {name = "Ahyeon", id = 31},
    {name = "Jongha", id = 34},
    {name = "Cheolsu", id = 37},
    {name = "Lisia", id = 40},
    {name = "Robert", id = 43},
    {name = "Paul", id = 47},
    {name = "Giant Kim", id = 51},
    {name = "Choji", id = 54},
    {name = "Dong Yeon", id = 57},
    {name = "Howon", id = 60},
    {name = "Hang Un", id = 63},
    {name = "Hyoung sup", id = 66},
    {name = "CaCO3", id = 73},
    {name = "Junhyung", id = 77},
    {name = "Seonghun", id = 80},
    {name = "Jini", id = 83},
    {name = "Gwangun", id = 86},
    {name = "Seon Woo", id = 89},
    {name = "Sachika", id = 92},
    {name = "Sohee", id = 95},
    {name = "Shimura", id = 97},
    {name = "Dae Hun", id = 100},
    {name = "Shin Sok", id = 102},
    {name = "Pramadara", id = 105},
    {name = "Jovan", id = 110},
    {name = "Nari", id = 112},
    {name = "Seung Min", id = 115},
    {name = "Viola", id = 157},
    {name = "NN", id = 161},
    {name = "Wooseok", id = 165},
    {name = "Falco", id = 168},
    {name = "Mateo", id = 172},
    {name = "Giuseppe", id = 175},
    {name = "Valentino", id = 179},
    {name = "Leonardo", id = 180},
    {name = "Lorenzo", id = 182},
    {name = "Ranti", id = 185},
    {name = "Marcus", id = 188},
    {name = "Ignacio", id = 191},
    {name = "Valentina", id = 195},
    {name = "Andrea", id = 197},
    {name = "Seol Hwa", id = 200},
    {name = "Kyle", id = 201},
    {name = "Mio", id = 204},
    {name = "Suri", id = 208},
    {name = "Suhan", id = 209},
    {name = "Nari", id = 211},
    {name = "Kim Beom", id = 214},
    {name = "Sodam", id = 215},
    {name = "Bidan", id = 219},
    {name = "Muyeong", id = 221},
    {name = "Sara", id = 230},
    {name = "Tania", id = 231},
    {name = "Lucas", id = 234},
    {name = "Levi", id = 236},
    {name = "Isla", id = 241},
    {name = "Hahyeon", id = 244},
    {name = "Canon", id = 250},
    {name = "Ellio", id = 252},
    {name = "Oskar", id = 255},
    {name = "Leo Haas", id = 256},
    {name = "Mika Dorn", id = 260},
    {name = "Kian", id = 265},
    {name = "Sven", id = 267},
    {name = "Gelato", id = 270},
    {name = "Tartufo", id = 273},
    {name = "Chianti", id = 276},
    {name = "Saffira", id = 279},
    {name = "NIKOLAI", id = 285},
    {name = "Zero", id = 286},
    {name = "Miren", id = 290},
    {name = "Enzo", id = 292},
    {name = "Tiziano", id = 298},
    {name = "Fedele", id = 300},
    {name = "Montepulciano", id = 304},
    {name = "Pesto", id = 307},
    {name = "Fedele", id = 309},
    {name = "Sunhang", id = 314},
    {name = "Sif", id = 323},
    {name = "Onyx", id = 329},
    {name = "Chris", id = 330},
    {name = "Semufreddo", id = 339},
    {name = "Cornetto", id = 342},
    {name = "Milanese", id = 345},
    {name = "Iris", id = 349},
    {name = "IVAN", id = 354},
    {name = "Rex", id = 367},
    {name = "Daisy", id = 370},
    {name = "Jihoon", id = 375},
    {name = "Haeun", id = 376},
    {name = "Kang Sejin", id = 386},
    {name = "Minseo Jo", id = 398},
    {name = "Sungjin Park", id = 401},
    {name = "Chei Yoo", id = 404},
    {name = "TEMP_NAME", id = 408},
}

local listWS = {
    {name = "Siwoo", id = 1},
    {name = "Inryeok", id = 5},
    {name = "Young Sup", id = 10},
    {name = "Yeong Jae", id = 13},
    {name = "Mysterious Grandpa", id = 16},
    {name = "Barae Choi", id = 21},
    {name = "Benchpress", id = 24},
    {name = "Jihwang", id = 27},
    {name = "Jaehyeon", id = 30},
    {name = "3C", id = 33},
    {name = "Seokgyu", id = 35},
    {name = "Yunseok", id = 39},
    {name = "Arugur", id = 42},
    {name = "Alex", id = 45},
    {name = "Brokoli", id = 49},
    {name = "Oasis", id = 50},
    {name = "Giant Choi", id = 53},
    {name = "Junseo", id = 56},
    {name = "Cheolwon", id = 59},
    {name = "Mirae", id = 62},
    {name = "Minjun", id = 65},
    {name = "Jinwoo", id = 68},
    {name = "Boreum", id = 71},
    {name = "Hyeonuk", id = 75},
    {name = "Kwangin", id = 79},
    {name = "Seonggwang", id = 82},
    {name = "Little Brother", id = 85},
    {name = "Han Beol", id = 88},
    {name = "Jae Seok", id = 91},
    {name = "Amane", id = 94},
    {name = "Nishikawa", id = 98},
    {name = "Jun Ho", id = 101},
    {name = "Luminor", id = 104},
    {name = "Sprout Lee", id = 107},
    {name = "Sota", id = 109},
    {name = "Leon", id = 158},
    {name = "Isabel", id = 159},
    {name = "Seokgi", id = 167},
    {name = "Giallo", id = 170},
    {name = "Francesco", id = 174},
    {name = "Giovanni", id = 177},
    {name = "Benedetto", id = 181},
    {name = "Federico", id = 184},
    {name = "Lazio", id = 187},
    {name = "Maximus", id = 190},
    {name = "Anselmo", id = 193},
    {name = "Alexandro", id = 198},
    {name = "DUMMY", id = 199},
    {name = "Hoyeon", id = 203},
    {name = "Saengwon", id = 205},
    {name = "Seonpung", id = 207},
    {name = "Haesu", id = 210},
    {name = "Hongsi", id = 212},
    {name = "Daram", id = 217},
    {name = "Hurim", id = 220},
    {name = "Jihwan", id = 224},
    {name = "Ryuhyun", id = 225},
    {name = "Dave", id = 228},
    {name = "Oliver", id = 235},
    {name = "Caleb", id = 240},
    {name = "Grace", id = 242},
    {name = "Evan", id = 243},
    {name = "Jenny", id = 251},
    {name = "Lene", id = 254},
    {name = "Dima Orlo", id = 257},
    {name = "Kira", id = 259},
    {name = "Lars Grell", id = 263},
    {name = "Pizzelle", id = 272},
    {name = "Espresso", id = 275},
    {name = "Prosecco", id = 278},
    {name = "Bazia", id = 281},
    {name = "Lucas", id = 284},
    {name = "Lucian", id = 289},
    {name = "Rian", id = 291},
    {name = "Massimo", id = 299},
    {name = "Salvatore", id = 301},
    {name = "Lasagna", id = 305},
    {name = "Peppino", id = 306},
    {name = "Duil", id = 315},
    {name = "Raul", id = 324},
    {name = "Vescari", id = 327},
    {name = "Aria", id = 331},
    {name = "Panna Cotta", id = 338},
    {name = "Mont Blanc", id = 341},
    {name = "Prosciutto", id = 344},
    {name = "SpikerSara", id = 351},
    {name = "Volkov", id = 353},
    {name = "Sergei", id = 355},
    {name = "Aira", id = 356},
    {name = "Hyeonuk", id = 362},
    {name = "Wyatt", id = 365},
    {name = "Logan", id = 369},
    {name = "Younghoon", id = 377},
    {name = "Vice Principal", id = 380},
    {name = "---", id = 383},
    {name = "---", id = 384},
    {name = "---", id = 385},
    {name = "Seo Yuna", id = 388},
    {name = "Jinhyun Kim", id = 399},
    {name = "Ivan Nam", id = 403},
    {name = "Jinkyeong Kim", id = 406},
}

local listWS1 = {
    {name = "Yongsub", id = 10, stats = {75, 60, 80, 45}, skins = { {name = "Default", id = -1} }},
    {name = "Jaehyun", id = 30, stats = {70, 70, 70, 70}, skins = { {name = "Default", id = -1}, {name = "Training", id = 3} }},
    {name = "Yoonseok", id = 39, stats = {45, 40, 55, 55}, skins = { {name = "Default", id = -1} }},
    {name = "Oasis", id = 50, stats = {55, 55, 55, 45}, skins = { {name = "Default", id = -1} }},
    {name = "Minjun", id = 65, stats = {30, 30, 55, 45}, skins = { {name = "Default", id = -1} }},
    {name = "Nishikawa", id = 98, stats = {95, 60, 60, 70}, skins = { {name = "Default", id = -1}, {name = "Highschool", id = 1}, {name = "Black", id = 4} }},
    {name = "Leon", id = 158, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1} }},
    {name = "Isabel", id = 159, stats = {20, 80, 25, 30}, skins = { {name = "Default", id = -1}, {name = "Wedding", id = 2} }},
    {name = "Hongsi", id = 212, stats = {65, 70, 70, 60}, skins = { {name = "Default", id = -1}, {name = "Maid", id = 14} }},
    {name = "Ryuhyeon", id = 225, stats = {70, 50, 50, 50}, skins = { {name = "Default", id = -1}, {name = "Dosa", id = 7}, {name = "Red Hood", id = 19} }},
    {name = "Dave", id = 228, stats = {40, 60, 60, 40}, skins = { {name = "Default", id = -1}, {name = "Diver", id = 10} }},
    {name = "Jenny", id = 251, stats = {50, 70, 55, 30}, skins = { {name = "Default", id = -1}, {name = "Straw Hat", id = 9}, {name = "Shooting Star", id = 17} }},
    {name = "Lucas", id = 284, stats = {60, 65, 60, 60}, skins = { {name = "Default", id = -1}, {name = "Summer Training", id = 22} }},
    {name = "Raul", id = 324, stats = {150, 90, 45, 70}, skins = { {name = "Default", id = -1} }},
    {name = "SpikerSara", id = 351, stats = {85, 55, 90, 55}, skins = { {name = "Default", id = -1} }},
    {name = "Seo Yuna", id = 388, stats = {80, 70, 70, 65}, skins = { {name = "Default", id = -1} }}, 
    {name = "Siwoo", id = 1, stats = {205, 205, 85, 70}, skins = { {name = "Default", id = -1} }}, 
    {name = "Alexandro", id = 198, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1} }}, 
    {name = "Kwangin", id = 79, stats = {55, 40, 55, 40}, skins = { {name = "Default", id = -1} }}, 
    {name = "Aira", id = 356, stats = {40, 55, 35, 40}, skins = { {name = "Default", id = -1} }}, 
    {name = "Wyatt", id = 365, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1} }}, 
    {name = "Evan", id = 243, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1} }}, 
    {name = "Grace", id = 242, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1} }}
}

local listMB1 = {
    {name = "Heeseong", id = 19, stats = {60, 50, 50, 50}, skins = { {name = "Default", id = -1} }},
    {name = "Atis", id = 44, stats = {70, 45, 35, 40}, skins = { {name = "Default", id = -1} }},
    {name = "Yamadera", id = 96, stats = {65, 60, 80, 45}, skins = { {name = "Default", id = -1} }},
    {name = "SangHyeon", id = 160, stats = {65, 50, 40, 55}, skins = { {name = "Default", id = -1} }},
    {name = "Roberto", id = 163, stats = {70, 75, 50, 55}, skins = { {name = "Default", id = -1} }},
    {name = "Hanra", id = 218, stats = {60, 40, 40, 55}, skins = { {name = "Default", id = -1}, {name = "Bread", id = 6}, {name = "Summer Training", id = 23} }},
    {name = "Mike", id = 229, stats = {35, 60, 65, 50}, skins = { {name = "Default", id = -1} }},
    {name = "Clyde", id = 232, stats = {65, 60, 60, 60}, skins = { {name = "Default", id = -1} }},
    {name = "Hari", id = 282, stats = {55, 45, 50, 40}, skins = { {name = "Default", id = -1}, {name = "Midnight", id = 18} }},
    {name = "Crow", id = 283, stats = {30, 55, 50, 30}, skins = { {name = "Default", id = -1} }},
    {name = "Claire", id = 322, stats = {65, 50, 50, 70}, skins = { {name = "Default", id = -1}, {name = "GodFather", id = 21} }},
    {name = "Yuri", id = 350, stats = {65, 75, 65, 65}, skins = { {name = "Default", id = -1} }},
    {name = "Saya", id = 374, stats = {45, 50, 60, 55}, skins = { {name = "Default", id = -1} }},
    {name = "Han Gitae", id = 387, stats = {90, 55, 40, 60}, skins = { {name = "Default", id = -1} }}, 
    {name = "Jaewon Lee", id = 400, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1} }}, 
    {name = "Walker", id = 368, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1} }}
}

local listSE1 = {
    {name = "Ahyeon", id = 31, stats = {50, 60, 60, 50}, skins = { {name = "Default", id = -1}, {name = "AhyeonStein", id = 5} }},
    {name = "Lisia", id = 40, stats = {0, 75, 75, 35}, skins = { {name = "Default", id = -1}, {name = "Rudolph", id = 13} }},
    {name = "Sohee", id = 95, stats = {55, 65, 65, 55}, skins = { {name = "Default", id = -1}, {name = "Vampire", id = 12} }},
    {name = "Viola", id = 157, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1}, {name = "Summer Training", id = 24} }},
    {name = "NN", id = 161, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1}, {name = "Surfer", id = 11} }},
    {name = "Solhwa", id = 200, stats = {70, 55, 65, 65}, skins = { {name = "Default", id = -1} }},
    {name = "Sodam", id = 215, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1} }},
    {name = "Muyeong", id = 221, stats = {70, 50, 75, 40}, skins = { {name = "Default", id = -1} }},
    {name = "Sara", id = 230, stats = {80, 50, 90, 70}, skins = { {name = "Default", id = -1}, {name = "Water Splash", id = 8} }},
    {name = "Tania", id = 231, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1} }},
    {name = "Ellio", id = 252, stats = {45, 70, 50, 45}, skins = { {name = "Default", id = -1}, {name = "Star Of The Encore", id = 16} }},
    {name = "Zero", id = 286, stats = {70, 45, 35, 60}, skins = { {name = "Default", id = -1}, {name = "Street Artist", id = 15} }},
    {name = "Sif", id = 323, stats = {60, 60, 60, 65}, skins = { {name = "Default", id = -1}, {name = "Bounty Hunter", id = 20} }},
    {name = "Iris", id = 349, stats = {70, 75, 90, 70}, skins = { {name = "Default", id = -1} }},
    {name = "Jihoon", id = 375, stats = {60, 55, 55, 45}, skins = { {name = "Default", id = -1} }},
    {name = "Kang Sejin", id = 386, stats = {65, 75, 75, 60}, skins = { {name = "Default", id = -1} }}, 
    {name = "Hahyeon", id = 244, stats = {55, 40, 40, 45}, skins = { {name = "Default", id = -1} }}, 
    {name = "Shimura", id = 97, stats = {55, 45, 40, 65}, skins = { {name = "Default", id = -1} }}, 
    {name = "Isla", id = 241, stats = {55, 55, 35, 35}, skins = { {name = "Default", id = -1} }}, 
    {name = "Levi", id = 236, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1} }}, 
    {name = "Kyle", id = 201, stats = {55, 55, 55, 55}, skins = { {name = "Default", id = -1} }}
}

local listWS2 = {
    {name = "Yongsub", id = 10, skins = { {name = "Default", id = -1} }},
    {name = "Jaehyun", id = 30, skins = { {name = "Default", id = -1}, {name = "Training", id = 3} }},
    {name = "Yoonseok", id = 39, skins = { {name = "Default", id = -1} }},
    {name = "Oasis", id = 50, skins = { {name = "Default", id = -1} }},
    {name = "Minjun", id = 65, skins = { {name = "Default", id = -1} }},
    {name = "Nishikawa", id = 98, skins = { {name = "Default", id = -1}, {name = "Highschool", id = 1}, {name = "Black", id = 4} }},
    {name = "Leon", id = 158, skins = { {name = "Default", id = -1} }},
    {name = "Isabel", id = 159, skins = { {name = "Default", id = -1}, {name = "Wedding", id = 2} }},
    {name = "Hongsi", id = 212, skins = { {name = "Default", id = -1}, {name = "Maid", id = 14} }},
    {name = "Ryuhyeon", id = 225, skins = { {name = "Default", id = -1}, {name = "Dosa", id = 7}, {name = "Red Hood", id = 19} }},
    {name = "Dave", id = 228, skins = { {name = "Default", id = -1}, {name = "Diver", id = 10} }},
    {name = "Jenny", id = 251, skins = { {name = "Default", id = -1}, {name = "Straw Hat", id = 9}, {name = "Shooting Star", id = 17} }},
    {name = "Lucas", id = 284, skins = { {name = "Default", id = -1}, {name = "Summer Training", id = 22} }},
    {name = "Raul", id = 324, skins = { {name = "Default", id = -1} }},
    {name = "SpikerSara", id = 351, skins = { {name = "Default", id = -1} }},
    {name = "Seo Yuna", id = 388, skins = { {name = "Default", id = -1} }}
}

local listMB2 = {
    {name = "Heeseong", id = 19, skins = { {name = "Default", id = -1} }},
    {name = "Atis", id = 44, skins = { {name = "Default", id = -1} }},
    {name = "Yamadera", id = 96, skins = { {name = "Default", id = -1} }},
    {name = "SangHyeon", id = 160, skins = { {name = "Default", id = -1} }},
    {name = "Roberto", id = 163, skins = { {name = "Default", id = -1} }},
    {name = "Hanra", id = 218, skins = { {name = "Default", id = -1}, {name = "Bread", id = 6}, {name = "Summer Training", id = 23} }},
    {name = "Mike", id = 229, skins = { {name = "Default", id = -1} }},
    {name = "Clyde", id = 232, skins = { {name = "Default", id = -1} }},
    {name = "Hari", id = 282, skins = { {name = "Default", id = -1}, {name = "Midnight", id = 18} }},
    {name = "Crow", id = 283, skins = { {name = "Default", id = -1} }},
    {name = "Claire", id = 322, skins = { {name = "Default", id = -1}, {name = "GodFather", id = 21} }},
    {name = "Yuri", id = 350, skins = { {name = "Default", id = -1} }},
    {name = "Saya", id = 374, skins = { {name = "Default", id = -1} }},
    {name = "Han Gitae", id = 387, skins = { {name = "Default", id = -1} }}
}

local listSE2 = {
    {name = "Ahyeon", id = 31, skins = { {name = "Default", id = -1}, {name = "AhyeonStein", id = 5} }},
    {name = "Lisia", id = 40, skins = { {name = "Default", id = -1}, {name = "Rudolph", id = 13} }},
    {name = "Sohee", id = 95, skins = { {name = "Default", id = -1}, {name = "Vampire", id = 12} }},
    {name = "Viola", id = 157, skins = { {name = "Default", id = -1}, {name = "Summer Training", id = 24} }},
    {name = "NN", id = 161, skins = { {name = "Default", id = -1}, {name = "Surfer", id = 11} }},
    {name = "Solhwa", id = 200, skins = { {name = "Default", id = -1} }},
    {name = "Sodam", id = 215, skins = { {name = "Default", id = -1} }},
    {name = "Muyeong", id = 221, skins = { {name = "Default", id = -1} }},
    {name = "Sara", id = 230, skins = { {name = "Default", id = -1}, {name = "Water Splash", id = 8} }},
    {name = "Tania", id = 231, skins = { {name = "Default", id = -1} }},
    {name = "Ellio", id = 252, skins = { {name = "Default", id = -1}, {name = "Star Of The Encore", id = 16} }},
    {name = "Zero", id = 286, skins = { {name = "Default", id = -1}, {name = "Street Artist", id = 15} }},
    {name = "Sif", id = 323, skins = { {name = "Default", id = -1}, {name = "Bounty Hunter", id = 20} }},
    {name = "Iris", id = 349, skins = { {name = "Default", id = -1} }},
    {name = "Jihoon", id = 375, skins = { {name = "Default", id = -1} }},
    {name = "Kang Sejin", id = 386, skins = { {name = "Default", id = -1} }}
}
-- ===== WING SPIKER SUB MENU =====
function WingSpikerMenu()
    currentMenu = 12
    local choices = {}
    for _, player in ipairs(listWS) do
        table.insert(choices, " " .. player.name)
    end
    table.insert(choices, " Return")    
    local menu = gg.choice(choices, 0, "• Select Wing Spiker •")
    if menu and menu ~= #choices then
        local selected = listWS[menu]
        executeHack(selected.id, selected.name, "Wing Spiker")
        WingSpikerMenu()
    elseif menu == #choices then
        EditStatOnly()
    end
end
-- ===== MIDDLE BLOCKER SUB MENU =====
function MiddleBlockerMenu()
    currentMenu = 13
    local choices = {}
    for _, player in ipairs(listMB) do
        table.insert(choices, " " .. player.name)
    end
    table.insert(choices, " Return")
    local menu = gg.choice(choices, 0, "• Select Middle Blocker •")
    if menu and menu ~= #choices then
        local selected = listMB[menu]
        executeHack(selected.id, selected.name, "Middle Blocker")
        MiddleBlockerMenu()
    elseif menu == #choices then
        EditStatOnly()
    end
end
-- ===== SETTER SUB MENU =====
function SetterMenu()
    currentMenu = 14
    local choices = {}
    for _, player in ipairs(listSE) do
        table.insert(choices, " " .. player.name)
    end
    table.insert(choices, " Return")
    local menu = gg.choice(choices, 0, "• Select Setter •")
    if menu and menu ~= #choices then
        local selected = listSE[menu]
        executeHack(selected.id, selected.name, "Setter")
        SetterMenu()
    elseif menu == #choices then
        EditStatOnly()
    end
end
-- ===== ALL CHARACTER ( SKIN + STAT ) MENU =====
function SkinStat()
    currentMenu = 10
    local menu = gg.choice({
        " Position Wing Spiker", 
        " Position Middle Blocker", 
        " Position Setter",
        " Return"
    }, 0, "• All Character ( Skin + Stat ) Menu •")
    if menu == 1 then
        RoleMenu1(listWS2, "Wing Spiker")
    elseif menu == 2 then
        RoleMenu1(listMB2, "Middle Blocker")
    elseif menu == 3 then
        RoleMenu1(listSE2, "Setter")
    elseif menu == 4 then
        CharacterMenu()
    end
end
-- ===== ALL CHARACTER ( SKIN + MAX STAT ) MENU =====
function SkinMaxStat()
    currentMenu = 11
    local menu = gg.choice({
        " Position Wing Spiker", 
        " Position Middle Blocker", 
        " Position Setter",
        " Return"
    }, 0, "• All Character ( Skin + Max Stat ) Menu •")
    if menu == 1 then
        RoleMenu(listWS1, "Wing Spiker")
    elseif menu == 2 then
        RoleMenu(listMB1, "Middle Blocker")
    elseif menu == 3 then
        RoleMenu(listSE1, "Setter")
    elseif menu == 4 then
        CharacterMenu()
    end
end
-- ===== GENERAL ROLE MENU =====
function RoleMenu(characterList, roleName)
    local choices = {}
    for _, player in ipairs(characterList) do
        table.insert(choices, " " .. player.name)
    end
    table.insert(choices, " Return")    
    local menu = gg.choice(choices, 0, "• Select " .. roleName .. " •")
    if menu and menu ~= #choices then
        local selectedPlayer = characterList[menu]
        SelectSkinMenu(selectedPlayer, roleName, characterList)
    elseif menu == #choices then
        SkinMaxStat()
    end
end

function RoleMenu1(characterList, roleName)
    local choices = {}
    for _, player in ipairs(characterList) do
        table.insert(choices, " " .. player.name)
    end
    table.insert(choices, " Return")    
    local menu = gg.choice(choices, 0, "• Select " .. roleName .. " •")
    if menu and menu ~= #choices then
        local selectedPlayer = characterList[menu]
        SelectSkinMenu1(selectedPlayer, roleName, characterList)
    elseif menu == #choices then
        SkinStat()
    end
end
-- ===== SUB MENU SKIN =====
function SelectSkinMenu(player, roleName, parentList)
    local choices = {}
    for _, skin in ipairs(player.skins) do
        table.insert(choices, " Skin: " .. skin.name)
    end
    table.insert(choices, " Return")   
    local menu = gg.choice(choices, 0, "• Select Skin for " .. player.name .. " •")
    if menu and menu ~= #choices then
        local selectedSkin = player.skins[menu]
        executeHack1(player, selectedSkin)
        SelectSkinMenu(player, roleName, parentList)
    elseif menu == #choices then
        RoleMenu(parentList, roleName)
    end
end

function SelectSkinMenu1(player, roleName, parentList)
    local choices = {}
    for _, skin in ipairs(player.skins) do
        table.insert(choices, " Skin: " .. skin.name)
    end
    table.insert(choices, " Return")    
    local menu = gg.choice(choices, 0, "• Select Skin for " .. player.name .. " •")
    if menu and menu ~= #choices then
        local selectedSkin = player.skins[menu]
        executeHackWithPrompt(player, selectedSkin)
        SelectSkinMenu1(player, roleName, parentList)
    elseif menu == #choices then
        RoleMenu1(parentList, roleName)
    end
end
-- ===== EXECUTE HACK =====
function executeHack(selectedPlayerID, playerName, roleName)
    local statPrompt = gg.prompt({
        "⚔️ Attack",
        "🛡️ Defense",
        "⚡ Speed",
        "⬆️ Jump"
    }, {"", "", "", ""}, {"number", "number", "number", "number"})
    if not statPrompt then
        gg.toast("❌ Canceled")
        return
    end
    local finalStats = {statPrompt[1], statPrompt[2], statPrompt[3], statPrompt[4]}
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber("-1", gg.TYPE_DOUBLE)
    local count = gg.getResultsCount()
    if count == 0 then
        gg.toast("❌ No results found")
        return
    end
    local results = gg.getResults(count)
    results = hiddenRefine(results, -0xb0, -1)
    results = hiddenRefine(results, 0xe0, -1)
    results = refineByRange(results, -0x40, "190~595")
    results = hiddenRefine(results, -0x80, selectedPlayerID)
    if not results or #results == 0 then
        gg.toast("⚠️ Refine failed / memory structure mismatch!")
        gg.clearResults()
        return
    end
    ---==== PLAYER STATS ====---
    editOffset(results, 0x0,   selectedPlayerID)   -- PlayerID
    editOffset(results, 0x20, 5)                  -- Ascension
    editOffset(results, 0xb0,  finalStats[1])      -- Attack
    editOffset(results, 0xe0,  finalStats[2])      -- Defense
    editOffset(results, 0x40, finalStats[3])      -- Speed
    editOffset(results, 0x10, finalStats[4])      -- Jump
    gg.clearResults()
    gg.toast("✅ " .. playerName .. " Successful Modified!")
end

function executeHack1(player, skin)
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber("-1", gg.TYPE_DOUBLE)
    local count = gg.getResultsCount()
    if count == 0 then
        gg.toast("❌ No results found")
        return
    end  
    local results = gg.getResults(count)
    results = hiddenRefine(results, -0xb0, -1)
    results = hiddenRefine(results, 0xe0, -1)
    results = refineByRange(results, -0x40, "190~595")
    results = hiddenRefine(results, -0x80, player.id)    
    if not results or #results == 0 then
        gg.toast("⚠️ Refine failed / memory structure mismatch!")
        gg.clearResults()
        return
    end    
    ---==== PLAYER STATS & SKIN OTOMATIS ====---
    editOffset(results, 0x0,   player.id)           -- Player ID
    editOffset(results, 0x20, 5)                  -- Ascension
    editOffset(results, 0xb0,  player.stats[1])     -- Attack
    editOffset(results, 0xe0,  player.stats[2])     -- Defense
    editOffset(results, 0x40, player.stats[3])     -- Speed
    editOffset(results, 0x10, player.stats[4])     -- Jump    
    if skin and skin.id then
        editOffset(results, 0xf0, skin.id)         -- Skin ID
    end
    gg.clearResults()
    gg.toast("✅ " .. player.name .. " [" .. skin.name .. "] Successful Modified!")
end

function executeHackWithPrompt(player, skin)
    local statPrompt = gg.prompt({
        "⚔️ Attack",
        "🛡️ Defense",
        "⚡ Speed",
        "⬆️ Jump"
    }, {}, {"number", "number", "number", "number"})    
    if not statPrompt then
        gg.toast(" Edit Canceled")
        return
    end   
    local finalStats = {
        tonumber(statPrompt[1]) or nil, 
        tonumber(statPrompt[2]) or nil, 
        tonumber(statPrompt[3]) or nil, 
        tonumber(statPrompt[4]) or nil
    }
    gg.setVisible(false)
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber("-1", gg.TYPE_DOUBLE)
    local count = gg.getResultsCount()
    if count == 0 then
        gg.toast(" No results found")
        return
    end    
    local results = gg.getResults(count)
    results = hiddenRefine(results, -0xb0, -1)
    results = hiddenRefine(results, 0xe0, -1)
    results = refineByRange(results, -0x40, "190~595")
    results = hiddenRefine(results, -0x80, player.id)
    if not results or #results == 0 then
        gg.toast("⚠️ Refine failed / memory structure mismatch!")
        gg.clearResults()
        return
    end
    ---==== EDIT PLAYER STATS & SKIN ====---
    editOffset(results, 0x0,   player.id)           -- Player ID
    editOffset(results, 0x20, 5)                  -- Ascension
    editOffset(results, 0xb0,  finalStats[1])       -- Attack
    editOffset(results, 0xe0,  finalStats[2])       -- Defense
    editOffset(results, 0x40, finalStats[3])       -- Speed
    editOffset(results, 0x10, finalStats[4])       -- Jump    
    if skin and skin.id then
        editOffset(results, 0xf0, skin.id)         -- Skin ID
    end
    gg.clearResults()
    gg.toast("✅ " .. player.name .. " [" .. skin.name .. "] Successfully Modified!")
end

local rawDataList = {
    "1. Siwoo, WS, B",
    "2. Jaeho, Se, C",
    "3. Ohjun, MB, B-",
    "4. Victor, Se, D",
    "5. Inryeok, WS, D+",
    "6. Hyunsoo, MB, C",
    "7. Jaehyun, Se, C",
    "8. Hanadu, MB, C",
    "9. Jeongbin, Se, D+",
    "10. Young Sup, WS, S",
    "11. Sehwan, Se, C-",
    "12. Eunsup, MB, C+",
    "13. Yeong Jae, WS, C+",
    "14. KimMin, Se, B-",
    "15. KwonMin, MB, C+",
    "16. Mysterious Grandpa, WS, A-",
    "19. Hee Sung, MB, S",
    "20. Isijak, MB, D",
    "21. Barae Choi, WS, D",
    "22. Proteo, Se, A",
    "23. Squat, MB, A",
    "24. Benchpress, WS, A",
    "25. Sin Bada, Se, C+",
    "26. Pureum, MB, A-",
    "27. Jihwang, WS, A",
    "28. Jaewook, Se, B-",
    "29. Yeongseok, MB, B+",
    "30. Jaehyeon, WS, S",
    "31. Ahyeon, Se, S",
    "32. 2KNO3, MB, B-",
    "33. 3C, WS, B",
    "34. Jongha, Se, B-",
    "35. Seokgyu, WS, C+",
    "37. Cheolsu, Se, B+",
    "38. Ilbong, MB, A-",
    "39. Yunseok, WS, S-",
    "40. Lisia, Se, S",
    "41. Sivir, MB, B",
    "42. Arugur, WS, A-",
    "43. Robert, Se, B+",
    "44. Atis, MB, S",
    "45. Alex, WS, B+",
    "47. Paul, Se, B+",
    "48. Kevin, MB, A-",
    "49. Brokoli, WS, A",
    "50. Oasis, WS, S",
    "51. Giant Kim, Se, B",
    "52. Giant Big, MB, B+",
    "53. Giant Choi, WS, B+",
    "54. Choji, Se, A",
    "55. Donggeon, MB, B+",
    "56. Junseo, WS, B",
    "57. Dong Yeon, Se, A-",
    "58. Min Gyu, MB, B+",
    "59. Cheolwon, WS, A",
    "60. Howon, Se, B",
    "61. Uiseong, MB, B",
    "62. Mirae, WS, B+",
    "63. Hang Un, Se, B",
    "64. Hyukjin, MB, B+",
    "65. Minjun, WS, S-",
    "66. Hyoung sup, Se, A",
    "67. Yongbi, MB, A",
    "68. Jinwoo, WS, A",
    "69. Hahyeon, Se, A+",
    "70. SangHyeon, MB, S",
    "71. Boreum, WS, A",
    "72. Seol Hwa, Se, S",
    "73. CaCO3, Se, B+",
    "74. Jiho, MB, A-",
    "75. Hyeonuk, WS, A-",
    "76. Dabin, MB, D",
    "77. Junhyung, Se, B-",
    "78. Heontae, MB, B",
    "79. Kwangin, WS, A+",
    "80. Seonghun, Se, A-",
    "81. Seongjwa, MB, B+",
    "82. Seonggwang, WS, A",
    "83. Jini, Se, A-",
    "84. Soin, MB, A-",
    "85. Little Brother, WS, A-",
    "86. Gwangun, Se, A-",
    "87. Eun Seong, MB, A-",
    "88. Han Beol, WS, B+",
    "89. Seon Woo, Se, A",
    "90. Seung Seon, MB, B+",
    "91. Jae Seok, WS, A-",
    "92. Sachika, Se, B",
    "93. Mizuho, MB, B+",
    "94. Amane, WS, B+",
    "95. Sohee, Se, S",
    "96. Yamadera, MB, S",
    "97. Shimura, Se, A+",
    "98. Nishikawa(ori), WS, S+",
    "99. Nishikawa(old), WS, S+",
    "100. Dae Hun, Se, B+",
    "101. Jun Ho, WS, B+",
    "102. Shin Sok, Se, A",
    "103. Park Cheetah, MB, A-",
    "104. Luminor, WS, A",
    "105. Pramadara, Se, C+",
    "106. Nae Gi, MB, C+",
    "107. Sprout Lee, WS, B",
    "108. Taichi, MB, A-",
    "109. Sota, WS, B+",
    "110. Jovan, Se, B+",
    "111. Young Sup, WS, C",
    "112. Nari, Se, A-",
    "113. Jangmi, MB, B+",
    "115. Seung Min, Se, C+",
    "116. B0 Player, WS, B",
    "157. Viola, Se, S-",
    "158. Leon, WS, S-",
    "159. Isabel, WS, S",
    "160. Sanghyeon, MB, S",
    "161. NN, Se, S",
    "163. Roberto, MB, S",
    "164. Nishikawa(Black), WS, S+",
    "165. Wooseok, Se, B-",
    "166. Dupal, MB, B",
    "167. Seokgi, WS, B+",
    "168. Falco, Se, A-",
    "169. Oslo, MB, B+",
    "170. Giallo, WS, D",
    "171. Verde, MB, A",
    "172. Mateo, Se, B+",
    "173. Marco, MB, A-",
    "174. Francesco, WS, B+",
    "175. Giuseppe, Se, B+",
    "176. Ricardo, MB, B",
    "177. Giovanni, WS, B+",
    "178. Alessia, MB, A",
    "179. Valentino, Se, B+",
    "180. Leonardo, Se, A",
    "181. Benedetto, WS, A",
    "182. Lorenzo, Se, A-",
    "183. Giacomo, MB, B+",
    "184. Federico, WS, B",
    "185. Ranti, Se, A",
    "186. Piano, MB, A-",
    "187. Lazio, WS, A-",
    "188. Marcus, Se, A-",
    "189. Lucius, MB, B+",
    "190. Maximus, WS, B+",
    "191. Ignacio, Se, A",
    "192. Leopoldo, MB, B+",
    "193. Anselmo, WS, B+",
    "195. Valentina, Se, C+",
    "196. Alessia, MB, B-",
    "197. Andrea, Se, A",
    "198. Alexandro, WS, A+",
    "199. DUMMY, WS, S-",
    "200. Seol Hwa, Se, S",
    "201. Kyle, Se, A+",
    "202. Taeho, MB, A+",
    "203. Hoyeon, WS, A+",
    "204. Mio, Se, A+",
    "205. Saengwon, WS, A+",
    "206. Jihwi, MB, A+",
    "207. Seonpung, WS, A+",
    "208. Suri, Se, A+",
    "209. Suhan, Se, A+",
    "210. Haesu, WS, A+",
    "211. Nari, Se, A-",
    "212. Hongsi, WS, S",
    "213. Daewoong, MB, A+",
    "214. Kim Beom, Se, A+",
    "215. Sodam, Se, S-",
    "216. Dalji, MB, A",
    "217. Daram, WS, B",
    "218. Hanra, MB, S",
    "219. Bidan, Se, A+",
    "220. Hurim, WS, A-",
    "221. Muyoung, Se, S",
    "223. Donggwan, MB, B-",
    "224. Jihwan, WS, A-",
    "225. Ryuhyun, WS, S+",
    "226. Ryuhyun, WS, S+",
    "227. Ryuhyun, WS, S+",
    "228. Dave, WS, S",
    "229. Mike, MB, S",
    "230. Sara, Se, S",
    "231. Tania, Se, S-",
    "232. Clyde, MB, S-",
    "233. Liam, MB, A-",
    "234. Lucas, Se, A-",
    "235. Oliver, WS, A",
    "236. Levi, Se, A+",
    "237. Dave, WS, S",
    "238. Mike, MB, S",
    "239. Gavin, MB, B+",
    "240. Caleb, WS, C+",
    "241. Isla, Se, A+",
    "242. Grace, WS, A+",
    "243. Evan, WS, A+",
    "244. Hahyeon, Se, A+",
    "245. Isabel - Wedding Dress, WS, S",
    "246. Jaehyeon - Training, WS, S",
    "247. Nishikawa, WS, S+",
    "248. Nishikawa - High School , WS, S+",
    "249. Kazuki, MB, A",
    "250. Canon, Se, A-",
    "251. Jenny, WS, S",
    "252. Ellio, Se, S",
    "253. Milo Zern, MB, A-",
    "254. Lene, WS, A-",
    "255. Oskar, Se, A-",
    "256. Leo Haas, Se, A",
    "257. Dima Orlo, WS, A",
    "258. Jure, MB, A-",
    "259. Kira, WS, B+",
    "260. Mika Dorn, Se, A",
    "261. Elva, MB, A",
    "262. Oren Bel, MB, A+",
    "263. Lars Grell, WS, A-",
    "265. Kian, Se, B+",
    "266. Theo, MB, A+",
    "267. Sven, Se, A+",
    "269. Alessia, MB, A",
    "270. Gelato, Se, A",
    "271. Tomat, MB, A-",
    "272. Pizzelle, WS, B",
    "273. Tartufo, Se, A+",
    "274. Cappuccino, MB, A",
    "275. Espresso, WS, A+",
    "276. Chianti, Se, B+",
    "277. Barolo, MB, A",
    "278. Prosecco, WS, A-",
    "279. Saffira, Se, C+",
    "280. Cinnamiel, MB, B",
    "281. Bazia, WS, B-",
    "282. Hari, MB, S",
    "283. Crow, MB, S-",
    "284. Lucas, WS, S+",
    "285. NIKOLAI, Se, A",
    "286. Zero, Se, S",
    "287. Dahee, Se, D",
    "288. Minerva, MB, A+",
    "289. Lucian, WS, A+",
    "290. Miren, Se, A+",
    "291. Rian, WS, B+",
    "292. Enzo, Se, A-",
    "293. Dante, MB, B+",
    "294. Raul, WS, S+",
    "295. 표승주, WS, S+",
    "296. Siwoo, WS, S+",
    "297. Bruno, MB, A+",
    "298. Tiziano, Se, A+",
    "299. Massimo, WS, A-",
    "300. Fedele, Se, A+",
    "301. Salvatore, WS, A+",
    "302. Enrico, MB, A+",
    "303. Eustachio, MB, A+",
    "304. Montepulciano, Se, A+",
    "305. Lasagna, WS, A+",
    "306. Peppino, WS, B+",
    "307. Pesto, Se, B+",
    "308. Burrata, MB, A+",
    "309. Fedele, Se, B+",
    "310. Eustachio, MB, A+",
    "311. Oasis, WS, S",
    "312. Lisia, Se, S",
    "313. NN(Surfer), Se, S",
    "314. Sunhang, Se, D",
    "315. Duil, WS, C",
    "316. Kim Jisam, MB, D+",
    "317. Seol Hwa, MB, S",
    "318. SoHee, Se, S",
    "319. Leon, WS, S-",
    "320. Viola, Se, S-",
    "321. SangHyeon, MB, S",
    "322. Claire, MB, S",
    "323. Sif, Se, S",
    "324. Raul, WS, S+",
    "325. Siwoo, WS, S+",
    "326. Valerio, MB, A+",
    "327. Vescari, WS, A-",
    "328. Obsidian, MB, A+",
    "329. Onyx, Se, A-",
    "330. Chris, Se, A+",
    "331. Aria, WS, B-",
    "332. Raul, WS, S+",
    "333. Oasis, WS, S",
    "334. Isabel, WS, S",
    "335. Crow, MB, S-",
    "336. Yongsub, WS, S",
    "337. Shimura, Se, A+",
    "338. Panna Cotta, WS, A+",
    "339. Semufreddo, Se, A+",
    "340. Granita, MB, A+",
    "341. Mont Blanc, WS, A+",
    "342. Cornetto, Se, A+",
    "343. Calzone, MB, A+",
    "344. Prosciutto, WS, A+",
    "345. Milanese, Se, A+",
    "346. Cacciatore, MB, A+",
    "347. NN, Se, S",
    "348. Chris, Se, A+",
    "349. Iris, Se, S",
    "350. Yuri, MB, S",
    "351. Sara, WS, S+",
    "352. Raul, WS, S+",
    "353. Volkov, WS, A",
    "354. IVAN, Se, A-",
    "355. Sergei, WS, A+",
    "356. Aira, WS, A+",
    "357. Yamadera, MB, S",
    "358. Mia, MB, A",
    "359. Shimura, Se, A+",
    "360. Ellio, Se, S",
    "361. Crow, MB, S-",
    "362. Hyeonuk, WS, A-",
    "363. Oasis, WS, S",
    "364. Dahee, Se, D",
    "365. Wyatt, WS, A+",
    "366. Shane, MB, B+",
    "367. Rex, Se, B+",
    "368. Walker, MB, A+",
    "369. Logan, WS, A+",
    "370. Daisy, Se, A+",
    "371. Ryuhyeon, WS, D",
    "372. Sif, MB, D",
    "373. Claire, Se, D",
    "374. Saya, MB, A+",
    "375. Jihoon, Se, A",
    "376. Haeun, Se, S",
    "377. Younghoon, WS, B+",
    "378. Young Sub, WS, S",
    "379. Jaeho, Se, C",
    "380. Vice Principal, WS, D",
    "381. Haeun, Se, S",
    "383. -, WS, D",
    "384. -, WS, D",
    "385. -, WS, D", 
    "386. Kang Sejin, Se, S", 
    "387. Han Gitae, MB, S+", 
    "388. Seo Yuna, WS, S", 
    "398. Minseo Jo, Se, B", 
    "399. Jinhyun Kim, WS, A-", 
    "400. Jaewon Lee, MB, A+", 
    "401. Sungjin Park, Se, B+", 
    "402. Seohee Pyeon, MB, A-", 
    "403. Ivan Nam, WS, B+", 
    "404. Chei Yoo, Se, A", 
    "405. Minseok Song, MB, B", 
    "406. Jinkyeong Kim, WS, A-", 
    "407. Heeseong, MB, S", 
    "408. TEMP_NAME, Se, B"
}

SAVE_FILE_PATH = gg.EXT_CACHE_DIR .. "/UserID.txt"

function saveSearchValue(val)
    local f = io.open(SAVE_FILE_PATH, "w")
    if f then
        f:write(tostring(val))
        f:close()
    end
end

function loadSearchValue()
    local f = io.open(SAVE_FILE_PATH, "r")
    if f then
        local val = f:read("*a")
        f:close()
        if val and #val > 0 then
            return tonumber(val) or val
        end
    end
    return nil
end

local safeSeed = 123456789
if rawDataList then
    safeSeed = (#rawDataList * 313) + 7
end
math.randomseed(safeSeed)

function customRefineFilter(results, offset, targetValue, flags)
    flags = flags or gg.TYPE_DOUBLE
    if not results or #results == 0 then return {} end    
    local check, refined = {}, {}
    for i, v in ipairs(results) do
        check[i] = {address = v.address + offset, flags = flags}
    end
    check = gg.getValues(check)
    if not check then return {} end
    local minVal, maxVal = string.match(tostring(targetValue or ""), "^(%d+%.?%d*)~(%d+%.?%d*)$")
    for _, v in ipairs(check) do
        if v and v.value then
            local val = tonumber(v.value)
            if val then
                if minVal and maxVal then
                    if val >= tonumber(minVal) and val <= tonumber(maxVal) then
                        refined[#refined + 1] = v
                    end
                else
                    if val == tonumber(targetValue) then
                        refined[#refined + 1] = v
                    end
                end
            end
        end
    end
    return refined
end

wsListPreset2 = {
    {name = "Yongsub", id = 10, skin = -1, stats = {75, 60, 80, 45}},
    {name = "Jaehyun", id = 30, skin = -1, stats = {70, 70, 70, 70}},
    {name = "Jaehyun_SkinTraining", id = 246, skin = -1, stats = {70, 70, 70, 70}},
    {name = "Yoonseok", id = 39, skin = -1, stats = {45, 40, 55, 55}},
    {name = "Oasis", id = 50, skin = -1, stats = {55, 55, 55, 45}},
    {name = "Minjun", id = 65, skin = -1, stats = {30, 30, 55, 45}},
    {name = "Leon", id = 158, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Isabel", id = 159, skin = -1, stats = {20, 80, 30, 10}},
    {name = "Isabel_SkinWedding", id = 245, skin = -1, stats = {20, 80, 30, 10}},
    {name = "Hongsi", id = 212, skin = -1, stats = {65, 70, 70, 60}},
    {name = "Hongsi_SkinMaid", id = 212, skin = 14, stats = {65, 70, 70, 60}},
    {name = "Ryuhyeon", id = 225, skin = -1, stats = {70, 50, 50, 50}},
    {name = "Ryuhyun_SkinDosa", id = 225, skin = 7, stats = {70, 50, 50, 50}},
    {name = "Ryuhyun_SkinRedHood", id = 225, skin = 19, stats = {70, 50, 50, 50}},
    {name = "Dave", id = 228, skin = -1, stats = {40, 60, 60, 40}},
    {name = "Dave_SkinDiver", id = 228, skin = 10, stats = {40, 60, 60, 40}},
    {name = "Jenny", id = 251, skin = -1, stats = {50, 70, 55, 30}},
    {name = "Jenny_SkinStrawHat", id = 251, skin = 9, stats = {50, 70, 55, 30}},
    {name = "Jenny_SkinShootingStar", id = 251, skin = 17, stats = {50, 70, 55, 30}},
    {name = "Lucas", id = 284, skin = -1, stats = {60, 65, 60, 60}},
    {name = "Lucas_SkinSummerTraining", id = 284, skin = 22, stats = {60, 65, 60, 60}},
    {name = "Raul", id = 324, skin = -1, stats = {150, 90, 45, 70}},
    {name = "Nishikawa", id = 98, skin = -1, stats = {95, 60, 55, 70}},
    {name = "Nishikawa", id = 99, skin = -1, stats = {144, 60, 60, 89}},
    {name = "Nishikawa_SkinHighschool_ForEventAI", id = 248, skin = -1, stats = {119, 60, 60, 89}},
    {name = "Nishikawa_SkinBlack", id = 164, skin = -1, stats = {154, 60, 55, 89}},
    {name = "SpikerSara", id = 351, skin = -1, stats = {85, 55, 90, 55}},
    {name = "Isabel", id = 334, skin = -1, stats = {20, 80, 25, 30}}, 
    {name = "King_Raul", id = 352, skin = -1, stats = {145, 60, 20, 65}},
    {name = "AwakenSiwoo_GetWeaker", id = 296, skin = -1, stats = {200, 100, 55, 75}}, 
    {name = "Seo Yuna", id = 388, skin = -1, stats = {80, 70, 70, 65}}, 
    {name = "DUMMY", id = 199, skin = -1, stats = {55, 55, 55, 55}}, 
    {name = "Kwangin", id = 79, skin = -1, stats = {55, 40, 55, 40}}, 
    {name = "Alexandro", id = 198, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Hoyeon", id = 203, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Saengwon", id = 205, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Seonpung", id = 207, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Haesu", id = 210, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Grace", id = 242, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Evan", id = 243, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Espresso", id = 275, skin = -1, stats = {40, 40, 25, 40}},
    {name = "Lucian", id = 289, skin = -1, stats = {35, 35, 35, 35}},
    {name = "Salvatore", id = 301, skin = -1, stats = {25, 55, 25, 25}},
    {name = "Lasagna", id = 305, skin = -1, stats = {55, 25, 55, 55}},
    {name = "Panna Cotta", id = 338, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Mont Blanc", id = 341, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Prosciutto", id = 344, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Sergei", id = 355, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Aira", id = 356, skin = -1, stats = {45, 55, 35, 45}},
    {name = "Wyatt", id = 365, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Logan", id = 369, skin = -1, stats = {55, 55, 55, 55}}
}

seListPreset2 = {
    {name = "Solhwa", id = 200, skin = -1, stats = {70, 55, 65, 65}},
    {name = "NN", id = 161, skin = -1, stats = {55, 55, 55, 55}},
    {name = "NN_SkinSurfer", id = 161, skin = 11, stats = {55, 55, 55, 55}},
    {name = "Viola", id = 157, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Viola_SkinSummerTraining", id = 157, skin = 24, stats = {55, 55, 55, 55}},
    {name = "Sohee", id = 95, skin = -1, stats = {55, 65, 65, 55}},
    {name = "Sohee_SkinVampire", id = 95, skin = 12, stats = {55, 65, 65, 55}},
    {name = "AhYeon", id = 31, skin = -1, stats = {50, 60, 60, 50}},
    {name = "Ahyeon_SkinAhyeonStein", id = 31, skin = 5, stats = {50, 60, 60, 50}},
    {name = "Lisia", id = 40, skin = -1, stats = {0, 75, 75, 35}},
    {name = "Lisia_SkinRudolph", id = 40, skin = 13, stats = {0, 75, 75, 35}},
    {name = "Mooyoung", id = 221, skin = -1, stats = {70, 50, 75, 40}},
    {name = "Sodam", id = 215, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Sara", id = 230, skin = -1, stats = {80, 50, 90, 70}},
    {name = "Sara_SkinWaterSplash", id = 230, skin = 8, stats = {80, 50, 90, 70}},
    {name = "Tania", id = 231, skin = -1, stats = {55, 55, 55, 55}},
    {name = "Ellio", id = 252, skin = -1, stats = {45, 70, 50, 45}},
    {name = "Ellio_SkinStarOfTheEncore", id = 252, skin = 16, stats = {45, 70, 50, 45}},
    {name = "Zero", id = 286, skin = -1, stats = {70, 45, 35, 60}},
    {name = "Zero_SkinStreetArtist", id = 286, skin = 15, stats = {70, 45, 35, 60}},
    {name = "Sif", id = 323, skin = -1, stats = {60, 60, 60, 65}},
    {name = "Sif_SkinBountyHunter", id = 323, skin = 20, stats = {60, 60, 60, 65}},
    {name = "Iris", id = 349, skin = -1, stats = {70, 75, 90, 70}},
    {name = "Jihoon", id = 375, skin = -1, stats = {60, 55, 55, 45}},
    {name = "Haeun", id = 376, skin = -1, stats = {60, 50, 55, 55}}, 
    {name = "Kang Sejin", id = 386, skin = -1, stats = {65, 75, 75, 60}}
}

mbListPreset2 = {
    {name = "Heeseong", id = 19, skin = -1, stats = {60, 50, 50, 50}},
    {name = "Roberto", id = 163, skin = -1, stats = {70, 75, 50, 55}},
    {name = "Atis", id = 44, skin = -1, stats = {70, 45, 35, 40}},
    {name = "Yamadera", id = 96, skin = -1, stats = {65, 60, 80, 45}},
    {name = "SangHyeon", id = 160, skin = -1, stats = {65, 50, 40, 55}},
    {name = "Hanra", id = 218, skin = -1, stats = {60, 40, 40, 55}},
    {name = "Hanra_SkinBread", id = 218, skin = 6, stats = {60, 40, 40, 55}},
    {name = "Hanra_SkinSummerTraining", id = 218, skin = 23, stats = {60, 40, 40, 55}},
    {name = "Mike", id = 229, skin = -1, stats = {35, 60, 65, 50}},
    {name = "Clyde", id = 232, skin = -1, stats = {65, 60, 60, 60}},
    {name = "Hari", id = 282, skin = -1, stats = {55, 45, 50, 40}},
    {name = "Hari_SkinMidnight", id = 282, skin = 18, stats = {55, 45, 50, 40}},
    {name = "Crow", id = 283, skin = -1, stats = {30, 55, 50, 30}},
    {name = "Claire", id = 322, skin = -1, stats = {65, 50, 50, 70}},
    {name = "Claire_SkinGodFather", id = 322, skin = 21, stats = {65, 50, 50, 70}},
    {name = "Yuri", id = 350, skin = -1, stats = {65, 75, 65, 65}},
    {name = "Saya", id = 374, skin = -1, stats = {60, 60, 60, 65}}, 
    {name = "Han Gitae", id = 387, skin = -1, stats = {90, 55, 40, 60}}
}

local customCharacterOverrides = {
    [1] = {name = "AwakenSiwoo_GetWeaker", id = 296, skin = -1, stats = {200, 100, 55, 75}},
    [2] = {name = "Oasis", id = 333, skin = -1, stats = {45, 50, 50, 70}},
    [3] = {name = "Isabel", id = 334, skin = -1, stats = {20, 80, 25, 30}}
}

function InjectionChar()
    gg.setVisible(false)
    gg.clearList()
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)  
    local newSearchValue = loadSearchValue()
    if not newSearchValue then
        gg.searchNumber("206398", gg.TYPE_DOUBLE)
        local count = gg.getResultsCount()
        if count == 0 then
            gg.toast("Initial value not found!")
            return
        end  
        local results = gg.getResults(count)
        results = customRefineFilter(results, -0x20, "247875", gg.TYPE_DOUBLE)
        if not results or #results == 0 then
            gg.toast("Value not found during refine!")
            return
        end   
        local checkOffset50 = {}
        for i, v in ipairs(results) do
            checkOffset50[i] = {address = v.address - 0xE0, flags = gg.TYPE_DOUBLE}
        end
        checkOffset50 = gg.getValues(checkOffset50)
        if not checkOffset50 or #checkOffset50 == 0 or not checkOffset50[1].value then
            gg.toast("Failed to read offset!")
            return
        end   
        newSearchValue = checkOffset50[1].value
        saveSearchValue(newSearchValue)
        gg.toast("💾 Auto Saved")
    else
        gg.toast("⚡ Auto Loaded")
    end    
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber(tostring(newSearchValue), gg.TYPE_DOUBLE)
    local count = gg.getResultsCount()
    if count == 0 then
        os.remove(SAVE_FILE_PATH)
        gg.toast("Value not found in memory! Cache file removed, please re-run the script.")
        return
    end
    local results = gg.getResults(count)
    results = customRefineFilter(results, 0x50, "190~595", gg.TYPE_DOUBLE)
    if not results or #results == 0 then
        gg.toast("Refine value not found!")
        return
    end   
    results = customRefineFilter(results, 0x10, "-1", gg.TYPE_DOUBLE)
    if not results or #results == 0 then
        gg.toast("Refine value not found!")
        return
    end
    results = customRefineFilter(results, -0xB0, "-1", gg.TYPE_DOUBLE)
    if not results or #results == 0 then
        gg.toast("Refine value not found!")
        return
    end
    local finalResults = {}
    for i, v in ipairs(results) do
        finalResults[i] = {address = v.address + 0x20, flags = gg.TYPE_DOUBLE}
    end
    finalResults = gg.getValues(finalResults)
    if not finalResults or #finalResults == 0 then
        gg.toast("Final values missing!")
        return
    end
    local totalDetected = #finalResults
    gg.toast("Detected " .. totalDetected .. " characters. Processing all characters.")   
    local rawNameMap = {}
    local rawRoleMap = {}
    for _, line in ipairs(rawDataList or {}) do
        if line then
            local id, name, role = string.match(line, "^%s*(%d+)%.%s*(.-)%s*,%s*(%a+)%s*,")
            if id and name and role then
                local numId = tonumber(id)
                rawNameMap[numId] = name
                role = string.upper(role)
                if role == "SETTER" or role == "SE" then role = "SE" end
                rawRoleMap[numId] = role
            end
        end
    end
    local wsPool = wsListPreset2
    local sePool = seListPreset2
    local mbPool = mbListPreset2
    local wsIndex, seIndex, mbIndex = 1, 1, 1
    local edits = {}
    local stats = {
        wsCount = 0,
        seCount = 0,
        mbCount = 0,
        unknownCount = 0,
        skippedCount = 0
    }
    local logWS = {}
    local logSE = {}
    local logMB = {}
    for i = 1, totalDetected do
        local item = finalResults[i]
        if item and item.value then
            local currentID = math.floor(item.value)
            local role = rawRoleMap[currentID]
            local originalName = rawNameMap[currentID] or ("Unknown (" .. currentID .. ")")                       
            local char = customCharacterOverrides[currentID]           
            if char then
                if role == "SE" then
                    stats.seCount = stats.seCount + 1
                    table.insert(logSE, originalName .. " ➔ " .. char.name)
                elseif role == "MB" then
                    stats.mbCount = stats.mbCount + 1
                    table.insert(logMB, originalName .. " ➔ " .. char.name)
                else
                    stats.wsCount = stats.wsCount + 1
                    table.insert(logWS, originalName .. " ➔ " .. char.name)
                end
            else
                if not role then
                    stats.unknownCount = stats.unknownCount + 1
                    role = "WS"
                end                
                if role == "WS" then
                    if wsIndex <= #wsPool then
                        char = wsPool[wsIndex]
                        wsIndex = wsIndex + 1
                        stats.wsCount = stats.wsCount + 1
                        table.insert(logWS, originalName .. " ➔ " .. char.name)
                    end
                elseif role == "SE" then
                    if seIndex <= #sePool then
                        char = sePool[seIndex]
                        seIndex = seIndex + 1
                        stats.seCount = stats.seCount + 1
                        table.insert(logSE, originalName .. " ➔ " .. char.name)
                    end
                elseif role == "MB" then
                    if mbIndex <= #mbPool then
                        char = mbPool[mbIndex]
                        mbIndex = mbIndex + 1
                        stats.mbCount = stats.mbCount + 1
                        table.insert(logMB, originalName .. " ➔ " .. char.name)
                    end
                end
            end
            if char and char.stats then
                local base = item.address
                edits[#edits + 1] = {address = base + 0x0,   flags = gg.TYPE_DOUBLE, value = char.id}       -- Player ID
                edits[#edits + 1] = {address = base + 0xF0,  flags = gg.TYPE_DOUBLE, value = char.skin}     -- Skin ID
                edits[#edits + 1] = {address = base + 0x20,  flags = gg.TYPE_DOUBLE, value = 5}             -- Ascension
                edits[#edits + 1] = {address = base + 0xB0,  flags = gg.TYPE_DOUBLE, value = char.stats[1]} -- Attack
                edits[#edits + 1] = {address = base + 0xE0,  flags = gg.TYPE_DOUBLE, value = char.stats[2]} -- Defense
                edits[#edits + 1] = {address = base + 0x40,  flags = gg.TYPE_DOUBLE, value = char.stats[3]} -- Speed
                edits[#edits + 1] = {address = base + 0x10,  flags = gg.TYPE_DOUBLE, value = char.stats[4]} -- Jump
            else
                stats.skippedCount = stats.skippedCount + 1
            end
        end
    end   
    if #edits > 0 then
        gg.setValues(edits)
    end
    gg.clearResults()
    gg.clearList()
    local totalUpdated = stats.wsCount + stats.seCount + stats.mbCount
    local function formatLogSection(title, list)
        local text = title .. ":\n"
        if #list == 0 then
            return text .. "  None\n"
        end
        for _, entry in ipairs(list) do
            text = text .. "  • " .. entry .. "\n"
        end
        return text
    end
    local wsLogStr = formatLogSection("Wing Spiker", logWS)
    local seLogStr = formatLogSection("Setter", logSE)
    local mbLogStr = formatLogSection("Middle Blocker", logMB)
    gg.alert(
        "📊 Character Injection Stats\n" ..
        "------------------------------------\n" ..
        "• Total Detected: " .. totalDetected .. "\n" ..
        "• Successfully Updated: " .. totalUpdated .. "\n\n" ..
        "📌 Role Breakdown:\n" ..
        "  - Wing Spiker (WS): " .. stats.wsCount .. "\n" ..
        "  - Setter (SE): " .. stats.seCount .. "\n" ..
        "  - Middle Blocker (MB): " .. stats.mbCount .. "\n\n" ..
        "⚠️ Alert Data:\n" ..
        "  - Unknown Values: " .. stats.unknownCount .. "\n" ..
        "  - Skipped: " .. stats.skippedCount .. "\n" ..
        "------------------------------------\n\n" ..
        "📋 Character Transition Details:\n\n" ..
        wsLogStr .. "\n" ..
        seLogStr .. "\n" ..
        mbLogStr ..
        "------------------------------------"
    )
end
-- ===== MAIN LOOP =====
gg.setVisible(true)
while true do
    if gg.isVisible(true) then
        gg.setVisible(false)
        if currentMenu == 1 then main()
        elseif currentMenu == 2 then CharacterMenu()
        elseif currentMenu == 3 then GameplayMenu()
        elseif currentMenu == 4 then StaminaMenu()
        elseif currentMenu == 5 then UnlimitedDurationSkillMenu()
        elseif currentMenu == 6 then EditScoreMenu()
        elseif currentMenu == 7 then LobbyMenu()
        elseif currentMenu == 8 then MiscMenu()
        elseif currentMenu == 9 then EditStatOnly()
        elseif currentMenu == 10 then SkinStat()
        elseif currentMenu == 11 then SkinMaxStat()
        elseif currentMenu == 12 then WingSpikerMenu()
        elseif currentMenu == 13 then MiddleBlockerMenu()
        elseif currentMenu == 14 then SetterMenu()
        elseif currentMenu == 15 then Mastery()
        end
    end
    gg.sleep(100)
end
end
maingetky()