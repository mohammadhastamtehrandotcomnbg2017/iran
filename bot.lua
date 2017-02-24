serpent = (loadfile "serpent.lua")()
redis = (loadfile "lua-redis.lua")()
lgi = require ('lgi')
database = Redis.connect('127.0.0.1', 6379)
notify = lgi.require('Notify')
notify.init ("Telegram updates")
chats = {}
day = 86400
bot_id = 259424620
sudo_users = {250049437}
  -----------------------------------------------------------------------------------------------
                                     -- start functions --
  -----------------------------------------------------------------------------------------------
function is_sudo(msg)
  local var = false
  for k,v in pairs(sudo_users) do
    if msg.sender_user_id_ == v then
      var = true
    end
  end
  return var
end
-----------------------------------------------------------------------------------------------
function is_admin(user_id)
    local var = false
	local hashs =  'bot:admins:'
    local admin = database:sismember(hashs, user_id)
	 if admin then
	    var = true
	 end
  for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
  end
    return var
end
-----------------------------------------------------------------------------------------------
function is_vip_group(gp_id)
    local var = false
	local hashs =  'bot:vipgp:'
    local vip = database:sismember(hashs, gp_id)
	 if vip then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
function is_owner(user_id, chat_id)
    local var = false
    local hash =  'bot:owners:'..chat_id
    local owner = database:sismember(hash, user_id)
	local hashs =  'bot:admins:'
    local admin = database:sismember(hashs, user_id)
	 if owner then
	    var = true
	 end
	 if admin then
	    var = true
	 end
    for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
	end
    return var
end
-----------------------------------------------------------------------------------------------
function is_mod(user_id, chat_id)
    local var = false
    local hash =  'bot:mods:'..chat_id
    local mod = database:sismember(hash, user_id)
	local hashs =  'bot:admins:'
    local admin = database:sismember(hashs, user_id)
	local hashss =  'bot:owners:'..chat_id
    local owner = database:sismember(hashss, user_id)
	 if mod then
	    var = true
	 end
	 if owner then
	    var = true
	 end
	 if admin then
	    var = true
	 end
    for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
	end
    return var
end
-----------------------------------------------------------------------------------------------
function is_banned(user_id, chat_id)
    local var = false
	local hash = 'bot:banned:'..chat_id
    local banned = database:sismember(hash, user_id)
	 if banned then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
function is_muted(user_id, chat_id)
    local var = false
	local hash = 'bot:muted:'..chat_id
    local banned = database:sismember(hash, user_id)
	 if banned then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
function is_gbanned(user_id)
    local var = false
	local hash = 'bot:gbanned:'
    local banned = database:sismember(hash, user_id)
	 if banned then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
local function check_filter_words(msg, value)
  local hash = 'bot:filters:'..msg.chat_id_
  if hash then
    local names = database:hkeys(hash)
    local text = ''
    for i=1, #names do
	   if string.match(value:lower(), names[i]:lower()) and not is_mod(msg.sender_user_id_, msg.chat_id_)then
	     local id = msg.id_
         local msgs = {[0] = id}
         local chat = msg.chat_id_
        delete_msg(chat,msgs)
       end
    end
  end
end
-----------------------------------------------------------------------------------------------
function resolve_username(username,cb)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, cb, nil)
end
  -----------------------------------------------------------------------------------------------
function changeChatMemberStatus(chat_id, user_id, status)
  tdcli_function ({
    ID = "ChangeChatMemberStatus",
    chat_id_ = chat_id,
    user_id_ = user_id,
    status_ = {
      ID = "ChatMemberStatus" .. status
    },
  }, dl_cb, nil)
end
  -----------------------------------------------------------------------------------------------
function getInputFile(file)
  if file:match('/') then
    infile = {ID = "InputFileLocal", path_ = file}
  elseif file:match('^%d+$') then
    infile = {ID = "InputFileId", id_ = file}
  else
    infile = {ID = "InputFilePersistentId", persistent_id_ = file}
  end

  return infile
end
  -----------------------------------------------------------------------------------------------
function del_all_msgs(chat_id, user_id)
  tdcli_function ({
    ID = "DeleteMessagesFromUser",
    chat_id_ = chat_id,
    user_id_ = user_id
  }, dl_cb, nil)
end
  -----------------------------------------------------------------------------------------------
function getChatId(id)
  local chat = {}
  local id = tostring(id)
  
  if id:match('^-100') then
    local channel_id = id:gsub('-100', '')
    chat = {ID = channel_id, type = 'channel'}
  else
    local group_id = id:gsub('-', '')
    chat = {ID = group_id, type = 'group'}
  end
  
  return chat
end
  -----------------------------------------------------------------------------------------------
function chat_leave(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, "Left")
end
  -----------------------------------------------------------------------------------------------
function from_username(msg)
   function gfrom_user(extra,result,success)
   if result.username_ then
   F = result.username_
   else
   F = 'nil'
   end
    return F
   end
  local username = getUser(msg.sender_user_id_,gfrom_user)
  return username
end
  -----------------------------------------------------------------------------------------------
function chat_kick(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, "Kicked")
end
  -----------------------------------------------------------------------------------------------
function do_notify (user, msg)
  local n = notify.Notification.new(user, msg)
  n:show ()
end
  -----------------------------------------------------------------------------------------------
local function getParseMode(parse_mode)  
  if parse_mode then
    local mode = parse_mode:lower()
  
    if mode == 'markdown' or mode == 'md' then
      P = {ID = "TextParseModeMarkdown"}
    elseif mode == 'html' then
      P = {ID = "TextParseModeHTML"}
    end
  end
  return P
end
  -----------------------------------------------------------------------------------------------
local function getMessage(chat_id, message_id,cb)
  tdcli_function ({
    ID = "GetMessage",
    chat_id_ = chat_id,
    message_id_ = message_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
function sendContact(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, phone_number, first_name, last_name, user_id)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = from_background,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessageContact",
      contact_ = {
        ID = "Contact",
        phone_number_ = phone_number,
        first_name_ = first_name,
        last_name_ = last_name,
        user_id_ = user_id
      },
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function sendPhoto(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, photo, caption)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = from_background,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessagePhoto",
      photo_ = getInputFile(photo),
      added_sticker_file_ids_ = {},
      width_ = 0,
      height_ = 0,
      caption_ = caption
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function getUserFull(user_id,cb)
  tdcli_function ({
    ID = "GetUserFull",
    user_id_ = user_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
function vardump(value)
  print(serpent.block(value, {comment=false}))
end
-----------------------------------------------------------------------------------------------
function dl_cb(arg, data)
end
-----------------------------------------------------------------------------------------------
local function send(chat_id, reply_to_message_id, disable_notification, text, disable_web_page_preview, parse_mode)
  local TextParseMode = getParseMode(parse_mode)
  
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = 1,
    reply_markup_ = nil,
    input_message_content_ = {
      ID = "InputMessageText",
      text_ = text,
      disable_web_page_preview_ = disable_web_page_preview,
      clear_draft_ = 0,
      entities_ = {},
      parse_mode_ = TextParseMode,
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function sendaction(chat_id, action, progress)
  tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessage" .. action .. "Action",
      progress_ = progress or 100
    }
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function changetitle(chat_id, title)
  tdcli_function ({
    ID = "ChangeChatTitle",
    chat_id_ = chat_id,
    title_ = title
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function edit(chat_id, message_id, reply_markup, text, disable_web_page_preview, parse_mode)
  local TextParseMode = getParseMode(parse_mode)
  tdcli_function ({
    ID = "EditMessageText",
    chat_id_ = chat_id,
    message_id_ = message_id,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessageText",
      text_ = text,
      disable_web_page_preview_ = disable_web_page_preview,
      clear_draft_ = 0,
      entities_ = {},
      parse_mode_ = TextParseMode,
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function setphoto(chat_id, photo)
  tdcli_function ({
    ID = "ChangeChatPhoto",
    chat_id_ = chat_id,
    photo_ = getInputFile(photo)
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function add_user(chat_id, user_id, forward_limit)
  tdcli_function ({
    ID = "AddChatMember",
    chat_id_ = chat_id,
    user_id_ = user_id,
    forward_limit_ = forward_limit or 50
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function unpinmsg(channel_id)
  tdcli_function ({
    ID = "UnpinChannelMessage",
    channel_id_ = getChatId(channel_id).ID
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function blockUser(user_id)
  tdcli_function ({
    ID = "BlockUser",
    user_id_ = user_id
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function unblockUser(user_id)
  tdcli_function ({
    ID = "UnblockUser",
    user_id_ = user_id
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
 local function reload()
loadfile("./bot.lua")()
end
-----------------------------------------------------------------------------------------------
local function getBlockedUsers(offset, limit)
  tdcli_function ({
    ID = "GetBlockedUsers",
    offset_ = offset,
    limit_ = limit
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function delete_msg(chatid,mid)
  tdcli_function ({
  ID="DeleteMessages", 
  chat_id_=chatid, 
  message_ids_=mid
  },
  dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function chat_del_user(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, 'Editor')
end
-----------------------------------------------------------------------------------------------
function getChannelMembers(channel_id, offset, filter, limit)
  if not limit or limit > 200 then
    limit = 200
  end
  tdcli_function ({
    ID = "GetChannelMembers",
    channel_id_ = getChatId(channel_id).ID,
    filter_ = {
      ID = "ChannelMembers" .. filter
    },
    offset_ = offset,
    limit_ = limit
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function getChannelFull(channel_id)
  tdcli_function ({
    ID = "GetChannelFull",
    channel_id_ = getChatId(channel_id).ID
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function channel_get_bots(channel,cb)
local function callback_admins(extra,result,success)
    limit = result.member_count_
    getChannelMembers(channel, 0, 'Bots', limit,cb)
    end
  getChannelFull(channel,callback_admins)
end
-----------------------------------------------------------------------------------------------
local function getInputMessageContent(file, filetype, caption)
  if file:match('/') then
    infile = {ID = "InputFileLocal", path_ = file}
  elseif file:match('^%d+$') then
    infile = {ID = "InputFileId", id_ = file}
  else
    infile = {ID = "InputFilePersistentId", persistent_id_ = file}
  end

  local inmsg = {}
  local filetype = filetype:lower()

  if filetype == 'animation' then
    inmsg = {ID = "InputMessageAnimation", animation_ = infile, caption_ = caption}
  elseif filetype == 'audio' then
    inmsg = {ID = "InputMessageAudio", audio_ = infile, caption_ = caption}
  elseif filetype == 'document' then
    inmsg = {ID = "InputMessageDocument", document_ = infile, caption_ = caption}
  elseif filetype == 'photo' then
    inmsg = {ID = "InputMessagePhoto", photo_ = infile, caption_ = caption}
  elseif filetype == 'sticker' then
    inmsg = {ID = "InputMessageSticker", sticker_ = infile, caption_ = caption}
  elseif filetype == 'video' then
    inmsg = {ID = "InputMessageVideo", video_ = infile, caption_ = caption}
  elseif filetype == 'voice' then
    inmsg = {ID = "InputMessageVoice", voice_ = infile, caption_ = caption}
  end

  return inmsg
end

-----------------------------------------------------------------------------------------------
function send_file(chat_id, type, file, caption,wtf)
local mame = (wtf or 0)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = mame,
    disable_notification_ = 0,
    from_background_ = 1,
    reply_markup_ = nil,
    input_message_content_ = getInputMessageContent(file, type, caption),
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function getUser(user_id, cb)
  tdcli_function ({
    ID = "GetUser",
    user_id_ = user_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
function pin(channel_id, message_id, disable_notification) 
   tdcli_function ({ 
     ID = "PinChannelMessage", 
     channel_id_ = getChatId(channel_id).ID, 
     message_id_ = message_id, 
     disable_notification_ = disable_notification 
   }, dl_cb, nil) 
end 
-----------------------------------------------------------------------------------------------
function tdcli_update_callback(data)
	-------------------------------------------
  if (data.ID == "UpdateNewMessage") then
    local msg = data.message_
    --vardump(data)
    local d = data.disable_notification_
    local chat = chats[msg.chat_id_]
	-------------------------------------------
	if msg.date_ < (os.time() - 30) then
       return false
    end
	-------------------------------------------
	if not database:get("bot:enable:"..msg.chat_id_) and not is_admin(msg.sender_user_id_, msg.chat_id_) then
      return false
    end
    -------------------------------------------
      if msg and msg.send_state_.ID == "MessageIsSuccessfullySent" then
	  --vardump(msg)
	   function get_mymsg_contact(extra, result, success)
             --vardump(result)
       end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,get_mymsg_contact)
         return false 
      end
    -------------* EXPIRE *-----------------
    if not database:get("bot:charge:"..msg.chat_id_) then
     if database:get("bot:enable:"..msg.chat_id_) then
      database:del("bot:enable:"..msg.chat_id_)
      for k,v in pairs(sudo_users) do
        send(v, 0, 1, "شارژ این گروه به اتمام رسید \nLink : "..(database:get("bot:group:link"..msg.chat_id_) or "تنظیم نشده").."\nID : "..msg.chat_id_..'\n\nدر صورتی که میخواهید ربات این گروه را ترک کند از دستور زیر استفاده کنید\n\n/leave'..msg.chat_id_..'\nبرای جوین دادن توی این گروه میتونی از دستور زیر استفاده کنی:\n/join'..msg.chat_id_..'\n_________________\nدر صورتی که میخواهید گروه رو دوباره شارژ کنید میتوانید از کد های زیر استفاده کنید...\n\n<code>برای شارژ 1 ماهه:</code>\n/plan1'..msg.chat_id_..'\n\n<code>برای شارژ 3 ماهه:</code>\n/plan2'..msg.chat_id_..'\n\n<code>برای شارژ نامحدود:</code>\n/plan3'..msg.chat_id_, 1, 'html')
      end
        send(msg.chat_id_, 0, 1, 'شارژ این گروه به اتمام رسید و ربات در گروه غیر فعال شد...\nبرای تمدید کردن ربات به @MohammadNBG پیام دهید.\nدر صورت ریپورت بودن میتوانید با ربات زیر با ما در ارتباط باشید:\n @MohammadNBGBot', 1, 'html')
        send(msg.chat_id_, 0, 1, 'ربات به دلایلی گروه را ترک میکند\nبرای اطلاعات بیشتر میتوانید با @MohammadNBG در ارتباط باشید.\nدر صورت ریپورت بودن میتوانید با ربات زیر به ما پیام دهید\n@MohamamdNBGBot\n\nChannel> @IranDevTeam', 1, 'html')
	   chat_leave(msg.chat_id_, bot_id)
      end
    end
     ----------------------------------------Anti FLood---------------------------------------------
      --------------Flood Max --------------
      local flmax = 'flood:max:'..msg.chat_id_
      if not database:get(flmax) then
        floodMax = 5
      else
        floodMax = tonumber(database:get(flmax))
      end
      -----------------End-------------------
      -----------------Msg-------------------
      local pm = 'flood:'..msg.sender_user_id_..':'..msg.chat_id_..':msgs'
      if not database:get(pm) then
        msgs = 0
      else
        msgs = tonumber(database:get(pm))
      end
      -----------------End-------------------
      ------------Flood Check Time-----------
      local TIME_CHECK = 2
      -----------------End-------------------
      -------------Flood Check---------------
      local hashflood = 'anti-flood:'..msg.chat_id_
      if msgs > (floodMax - 1) then
        if database:get('floodstatus'..msg.chat_id_) == 'Kicked' then
          del_all_msgs(msg.chat_id_, msg.sender_user_id_)
          chat_kick(msg.chat_id_, msg.sender_user_id_)
        elseif database:get('floodstatus'..msg.chat_id_) == 'DelMsg' then
          del_all_msgs(msg.chat_id_, msg.sender_user_id_)
        else
          del_all_msgs(msg.chat_id_, msg.sender_user_id_)del_all_msgs(msg.chat_id_, msg.sender_user_id_)
        end
      end
	-------------------------------------------
	database:incr("bot:allmsgs")
	if msg.chat_id_ then
      local id = tostring(msg.chat_id_)
      if id:match('-100(%d+)') then
        if not database:sismember("bot:groups",msg.chat_id_) then
            database:sadd("bot:groups",msg.chat_id_)
        end
        elseif id:match('^(%d+)') then
        if not database:sismember("bot:userss",msg.chat_id_) then
            database:sadd("bot:userss",msg.chat_id_)
        end
        else
        if not database:sismember("bot:groups",msg.chat_id_) then
            database:sadd("bot:groups",msg.chat_id_)
        end
     end
    end
	-------------------------------------------
    -------------* MSG TYPES *-----------------
     if msg.content_ then
      if msg.reply_markup_ and  msg.reply_markup_.ID == "ReplyMarkupInlineKeyboard" then
        --if msg.reply_markup_.ID == "ReplyMarkupInlineKeyboard" then
          print("This is [ Inline ]")
          msg_type = 'MSG:Inline'
        end
        -------------------------
        if msg.content_.ID == "MessageText" then
          text = msg.content_.text_
          print("This is [ Text ]")
          msg_type = 'MSG:Text'
        end
        -------------------------
        if msg.content_.ID == "MessagePhoto" then
          print("This is [ Photo ]")
          if msg.content_.caption_ then
            caption_text = msg.content_.caption_
          end
          msg_type = 'MSG:Photo'
        end
        -------------------------
        if msg.content_.ID == "MessageChatAddMembers" then
          print("This is [ New User Add ]")
          msg_type = 'MSG:NewUserAdd'
        end
        -----------------------------------
        if msg.content_.ID == "MessageDocument" then
          print("This is [ File Or Document ]")
          msg_type = 'MSG:Document'
        end
        -------------------------
        if msg.content_.ID == "MessageSticker" then
          print("This is [ Sticker ]")
          msg_type = 'MSG:Sticker'
        end
        -------------------------
        if msg.content_.ID == "MessageAudio" then
          print("This is [ Audio ]")
          if msg.content_.caption_ then
            caption_text = msg.content_.caption_
          end
          msg_type = 'MSG:Audio'
        end
        -------------------------
        if msg.content_.ID == "MessageVoice" then
          print("This is [ Voice ]")
          if msg.content_.caption_ then
            caption_text = msg.content_.caption_
          end
          msg_type = 'MSG:Voice'
        end
        -------------------------
        if msg.content_.ID == "MessageVideo" then
          print("This is [ Video ]")
          if msg.content_.caption_ then
            caption_text = msg.content_.caption_
          end
          msg_type = 'MSG:Video'
        end
        -------------------------
        if msg.content_.ID == "MessageAnimation" then
          print("This is [ Gif ]")
          if msg.content_.caption_ then
            caption_text = msg.content_.caption_
          end
          msg_type = 'MSG:Gif'
        end
        -------------------------
        if msg.content_.ID == "MessageLocation" then
          print("This is [ Location ]")
          if msg.content_.caption_ then
            caption_text = msg.content_.caption_
          end
          msg_type = 'MSG:Location'
        end
        -------------------------
        if msg.content_.ID == "MessageChatJoinByLink" or msg.content_.ID == "MessageChatAddMembers" then
          print("This is [ Msg Join ]")
          msg_type = 'MSG:NewUser'
        end
        -------------------------
        if msg.content_.ID == "MessageChatJoinByLink" then
          print("This is [ Msg Join By Link ]")
          msg_type = 'MSG:JoinByLink'
        end
        -------------------------
        if msg.content_.ID == "MessageContact" then
          print("This is [ Contact ]")
          if msg.content_.caption_ then
            caption_text = msg.content_.caption_
          end
          msg_type = 'MSG:Contact'
        end
        -------------------------
      end
      -------------------------------------------
      if ((not d) and chat) then
        if msg.content_.ID == "MessageText" then
          do_notify (chat.title_, msg.content_.text_)
        else
          do_notify (chat.title_, msg.content_.ID)
        end
      end
    -------------------------------------------
    -------------------------------------------
    if ((not d) and chat) then
      if msg.content_.ID == "MessageText" then
        do_notify (chat.title_, msg.content_.text_)
      else
        do_notify (chat.title_, msg.content_.ID)
      end
    end
  -----------------------------------------------------------------------------------------------
                                     -- end functions --
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
                                     -- start code --
  -----------------------------------------------------------------------------------------------
  -------------------------------------- Process mod --------------------------------------------
  -----------------------------------------------------------------------------------------------
  
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  --------------------------******** START MSG CHECKS ********-------------------------------------------
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
if is_banned(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
		  chat_kick(msg.chat_id_, msg.sender_user_id_)
		  return 
end
if is_muted(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
          delete_msg(chat,msgs)
		  return 
end
if is_gbanned(msg.sender_user_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
		  chat_kick(msg.chat_id_, msg.sender_user_id_)
		   return 
end	
if database:get('bot:muteall'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
        return 
end
    database:incr('user:msgs'..msg.chat_id_..':'..msg.sender_user_id_)
	database:incr('group:msgs'..msg.chat_id_)
if msg.content_.ID == "MessagePinMessage" then
  if database:get('pinnedmsg'..msg.chat_id_) and database:get('bot:pin:mute'..msg.chat_id_) then
   send(msg.chat_id_, msg.id_, 1, 'شما دسترسی به این کار را ندارید...\nمن پیام شما را آنپین و در صورت در دسترس بودن پیام قبل رو دوباره پین میکنم...\nدر صورتی که در ربات مقامی دارید میتوانید با ریپلی کردن پیام و ارسال دستور /pin پیام جدید رو برای پین شدن تنظیم کنید!', 1, 'md')
   unpinmsg(msg.chat_id_)
   local pin_id = database:get('pinnedmsg'..msg.chat_id_)
         pin(msg.chat_id_,pin_id,0)
   end
end
if database:get('bot:viewget'..msg.sender_user_id_) then 
    if not msg.forward_info_ then
		send(msg.chat_id_, msg.id_, 1, '_ارور 404_\n_پست را حتما باید فروراد کنید از کانال_', 1, 'md')
		database:del('bot:viewget'..msg.sender_user_id_)
	else
		send(msg.chat_id_, msg.id_, 1, '_تعداد بازدید پست شما_: '..msg.views_..' بازدید!', 1, 'md')
        database:del('bot:viewget'..msg.sender_user_id_)
	end
end
if msg_type == 'MSG:Photo' then
   --vardump(msg)
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
     if database:get('bot:photo:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   if caption_text then
      check_filter_words(msg, caption_text)
   if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") or caption_text:match("[Tt][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Dd][Oo][Gg]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("@") or msg.content_.entities_[0].ID and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
     if msg.content_.entities_[0].ID == "MessageEntityBold" or msg.content_.entities_[0].ID == "MessageEntityCode" or msg.content_.entities_[0].ID == "MessageEntityPre" or msg.content_.entities_[0].ID == "MessageEntityItalic" then
   if database:get('bot:markdown:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
    if caption_text:match("شارژ") or caption_text:match("همراه اول") or caption_text:match("ایرانسل") or caption_text:match("کد") or caption_text:match("رایگان") or caption_text:match("همراه") then
   if database:get('bot:operator:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
  elseif msg_type == 'MSG:Inline' then
   if not is_mod(msg.sender_user_id_, msg.chat_id_) then
    if database:get('bot:inline:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   end
  elseif msg_type == 'MSG:Sticker' then
   if not is_mod(msg.sender_user_id_, msg.chat_id_) then
  if database:get('bot:sticker:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   end
elseif msg_type == 'MSG:NewUserLink' then
  if database:get('bot:tgservice:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   function get_welcome(extra,result,success)
    if database:get('welcome:'..msg.chat_id_) then
        text = database:get('welcome:'..msg.chat_id_)
    else
        text = '*Hi {firstname} 😃*'
    end
    local text = text:gsub('{firstname}',(result.first_name_ or ''))
    local text = text:gsub('{lastname}',(result.last_name_ or ''))
    local text = text:gsub('{username}',(result.username_ or ''))
         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
   end
	  if database:get("bot:welcome"..msg.chat_id_) then
        getUser(msg.sender_user_id_,get_welcome)
      end
elseif msg_type == 'MSG:NewUserAdd' then
  if database:get('bot:tgservice:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
      --vardump(msg)
   if msg.content_.members_[0].username_ and msg.content_.members_[0].username_:match("[Bb][Oo][Tt]$") then
      if database:get('bot:bots:mute'..msg.chat_id_) and not is_mod(msg.content_.members_[0].id_, msg.chat_id_) then
		 chat_kick(msg.chat_id_, msg.content_.members_[0].id_)
		 return false
	  end
   end
   if is_banned(msg.content_.members_[0].id_, msg.chat_id_) then
		 chat_kick(msg.chat_id_, msg.content_.members_[0].id_)
		 return false
   end
   if database:get("bot:welcome"..msg.chat_id_) then
    if database:get('welcome:'..msg.chat_id_) then
        text = database:get('welcome:'..msg.chat_id_)
    else
        text = '*Hi {firstname} 😃*'
    end
    local text = text:gsub('{firstname}',(msg.content_.members_[0].first_name_ or ''))
    local text = text:gsub('{lastname}',(msg.content_.members_[0].last_name_ or ''))
    local text = text:gsub('{username}',('@'..msg.content_.members_[0].username_ or ''))
         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
   end
elseif msg_type == 'MSG:Contact' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:contact:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   end
elseif msg_type == 'MSG:Audio' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:music:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   if caption_text then
      check_filter_words(msg, caption_text)
   if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") or caption_text:match("[Tt][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Dd][Oo][Gg]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
 if caption_text:match("@") or msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if msg.content_.entities_[0].ID == "MessageEntityBold" or msg.content_.entities_[0].ID == "MessageEntityCode" or msg.content_.entities_[0].ID == "MessageEntityPre" or msg.content_.entities_[0].ID == "MessageEntityItalic" then
   if database:get('bot:markdown:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
  	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
    if caption_text:match("شارژ") or caption_text:match("همراه اول") or caption_text:match("ایرانسل") or caption_text:match("کد") or caption_text:match("رایگان") or caption_text:match("همراه") then
   if database:get('bot:operator:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
     if caption_text:match("[\216-\219][\128-\191]") then
    if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
elseif msg_type == 'MSG:Voice' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:voice:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
   if caption_text then
      check_filter_words(msg, caption_text)
  if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") or caption_text:match("[Tt][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Dd][Oo][Gg]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
  if caption_text:match("@") then
  if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if msg.content_.entities_[0].ID == "MessageEntityBold" or msg.content_.entities_[0].ID == "MessageEntityCode" or msg.content_.entities_[0].ID == "MessageEntityPre" or msg.content_.entities_[0].ID == "MessageEntityItalic" then
   if database:get('bot:markdown:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
    if caption_text:match("شارژ") or caption_text:match("همراه اول") or caption_text:match("ایرانسل") or caption_text:match("کد") or caption_text:match("رایگان") or caption_text:match("همراه") then
   if database:get('bot:operator:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	 if caption_text:match("[\216-\219][\128-\191]") then
    if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
elseif msg_type == 'MSG:Location' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:location:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
   if caption_text then
      check_filter_words(msg, caption_text)
   if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") or caption_text:match("[Tt][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Dd][Oo][Gg]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("@") or msg.content_.entities_[0].ID and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if msg.content_.entities_[0].ID == "MessageEntityBold" or msg.content_.entities_[0].ID == "MessageEntityCode" or msg.content_.entities_[0].ID == "MessageEntityPre" or msg.content_.entities_[0].ID == "MessageEntityItalic" then
   if database:get('bot:markdown:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
     if caption_text:match("شارژ") or caption_text:match("همراه اول") or caption_text:match("ایرانسل") or caption_text:match("کد") or caption_text:match("رایگان") or caption_text:match("همراه") then
   if database:get('bot:operator:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
elseif msg_type == 'MSG:Video' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:video:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
   if caption_text then
      check_filter_words(msg, caption_text)
  if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") or caption_text:match("[Tt][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Dd][Oo][Gg]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("@") or msg.content_.entities_[0].ID and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if msg.content_.entities_[0].ID == "MessageEntityBold" or msg.content_.entities_[0].ID == "MessageEntityCode" or msg.content_.entities_[0].ID == "MessageEntityPre" or msg.content_.entities_[0].ID == "MessageEntityItalic" then
   if database:get('bot:markdown:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
    if caption_text:match("شارژ") or caption_text:match("همراه اول") or caption_text:match("ایرانسل") or caption_text:match("کد") or caption_text:match("رایگان") or caption_text:match("همراه") then
   if database:get('bot:operator:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
elseif msg_type == 'MSG:Gif' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   if database:get('bot:gifs:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
   if caption_text then
   check_filter_words(msg, caption_text)
   if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") or caption_text:match("[Tt][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Dd][Oo][Gg]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("@") or msg.content_.entities_[0].ID and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if msg.content_.entities_[0].ID == "MessageEntityBold" or msg.content_.entities_[0].ID == "MessageEntityCode" or msg.content_.entities_[0].ID == "MessageEntityPre" or msg.content_.entities_[0].ID == "MessageEntityItalic" then
   if database:get('bot:markdown:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
     if caption_text:match("شارژ") or caption_text:match("همراه اول") or caption_text:match("ایرانسل") or caption_text:match("کد") or caption_text:match("رایگان") or caption_text:match("همراه") then
   if database:get('bot:operator:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end	
   end
elseif msg_type == 'MSG:Text' then
 --vardump(msg)
    if database:get("bot:group:link"..msg.chat_id_) == 'Waiting For Link!\nPls Send Group Link.\n\nJoin My Channel > @IranDevTeam' and is_mod(msg.sender_user_id_, msg.chat_id_) then
      if text:match("(https://telegram.me/joinchat/%S+)") or text:match("(https://t.me/joinchat/%S+)") or text:match("(https://telegram.dog/joinchat/%S+)") then
	  local glink = text:match("(https://telegram.me/joinchat/%S+)") or text:match("(https://t.me/joinchat/%S+)") or text:match("(https://telegram.dog/joinchat/%S+)")
      local hash = "bot:group:link"..msg.chat_id_
               database:set(hash,glink)
			  send(msg.chat_id_, msg.id_, 1, '_لینک گروه تنظیم شد_', 1, 'md')
			  send(msg.chat_id_, 0, 1, '_لینک گروه :_\n'..glink, 1, 'html')
      end
   end
    function check_username(extra,result,success)
	 --vardump(result)
	local username = (result.username_ or '')
	local svuser = 'user:'..result.id_
	if username then
      database:hset(svuser, 'username', username)
    end
	if username and username:match("[Bb][Oo][Tt]$") then
      if database:get('bot:bots:mute'..msg.chat_id_) and not is_mod(result.id_, msg.chat_id_) then
		 chat_kick(msg.chat_id_, result.id_)
		 return false
		 end
	  end
   end
    getUser(msg.sender_user_id_,check_username)
   database:set('bot:editid'.. msg.id_,msg.content_.text_)
   if not is_mod(msg.sender_user_id_, msg.chat_id_) then
    check_filter_words(msg, text)
	if text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") or text:match("[Tt][Mm].[Mm][Ee]") or text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Dd][Oo][Gg]") then
     if database:get('bot:links:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
	if text then
     if database:get('bot:text:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   if text:match("@") or msg.content_.entities_[0] and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if text:match("#") then
      if database:get('bot:hashtag:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if text:match("[Hh][Tt][Tt][Pp][Ss]://") or text:match("[Hh][Tt][Tt][Pp]://") or text:match(".[Ii][Rr]") or text:match(".[Cc][Oo][Mm]") or text:match(".[Oo][Rr][Gg]") or text:match(".[Ii][Nn][Ff][Oo]") or text:match("[Ww][Ww][Ww].") or text:match(".[Tt][Kk]") then
      if database:get('bot:webpage:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
     if text:match("شارژ") or text:match("همراه اول") or text:match("ایرانسل") or text:match("کد") or text:match("رایگان") or text:match("همراه") then
   if database:get('bot:operator:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if text:match("[\216-\219][\128-\191]") then
      if database:get('bot:arabic:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	  if text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
      if database:get('bot:english:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	  end
     end
    end
   end
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  ---------------------------******** END MSG CHECKS ********--------------------------------------------
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  if database:get('bot:cmds'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
  return 
  else
    ------------------------------------ With Pattern -------------------------------------------
	if text:match("^[#!/]ping$") then
	   send(msg.chat_id_, msg.id_, 1, '_Pong_', 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[!/#]leave$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	     chat_leave(msg.chat_id_, bot_id)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([pP][rR][Oo][mM][oO][Tt][eE])$") and is_owner(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function promote_by_reply(extra, result, success)
	local hash = 'bot:mods:'..msg.chat_id_
	if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _از قبل مقام دستیار مدیر را داشته است_', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _به مقام دستیار مدیر ارتقاء یافت_', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,promote_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([pP][rR][Oo][mM][oO][Tt][eE]) @(.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([pP][rR][Oo][mM][oO][Tt][eE]) @(.*)$")} 
	function promote_by_username(extra, result, success)
	if result.id_ then
	        database:sadd('bot:mods:'..msg.chat_id_, result.id_)
            texts = '_کاربر_ <code>@'..result.id_..'</code> _به مقام دستیار مدیر ارتقاء یافت_'
            else 
            texts = '<code>این کاربر در گروه یافت نشد</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],promote_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([pP][rR][Oo][mM][oO][Tt][eE]) (%d+)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([pP][rR][Oo][mM][oO][Tt][eE]) (%d+)$")} 	
	        database:sadd('bot:mods:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..ap[2]..'* _به مقام دستیار مدیر ارتقاء یافت_', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([dD][eE][mM][oO][Tt][eE])$") and is_owner(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function demote_by_reply(extra, result, success)
	local hash = 'bot:mods:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _از قبل مدیر نبوده است!_', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _از مقام مدیری عزل شد و اکنون یک کاربر عادی میباشد_', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,demote_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([dD][eE][mM][oO][Tt][eE]) @(.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:mods:'..msg.chat_id_
	local ap = {string.match(text, "^[#/!]([dD][eE][mM][oO][Tt][eE]) @(.*)$")} 
	function demote_by_username(extra, result, success)
	if result.id_ then
         database:srem(hash, result.id_)
            _texts = '_کاربر_ <code>@'..result.id_..'</code> _از مقام مدیری عزل شد و اکنون یک کاربر عادی میباشد_'
            else 
            texts = '<code>این کاربر در گروه یافت نشد</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],demote_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([dD][eE][mM][oO][Tt][eE]) (%d+)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:mods:'..msg.chat_id_
	local ap = {string.match(text, "^[#/!]([dD][eE][mM][oO][Tt][eE]) (%d+)$")} 	
         database:srem(hash, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..ap[2]..'* _از مقام مدیری عزل شد و اکنون یک کاربر عادی میباشد_', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([bB][aA][nN])$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function ban_by_reply(extra, result, success)
	local hash = 'bot:banned:'..msg.chat_id_
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_شما نمیتوانید افراد مقام دار را بن کنید!_', 1, 'md')
    else
    if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _از قبل بن شده است_', 1, 'md')
		 chat_kick(result.chat_id_, result.sender_user_id_)
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _از گروه بن شد_', 1, 'md')
		 chat_kick(result.chat_id_, result.sender_user_id_)
	end
    end
	end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,ban_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([bB][aA][nN]) @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([bB][aA][nN]) @(.*)$")} 
	function ban_by_username(extra, result, success)
	if result.id_ then
	if is_mod(result.id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_شما نمیتوانید افراد مقام دار را بن کنید!_', 1, 'md')
    else
	        database:sadd('bot:banned:'..msg.chat_id_, result.id_)
            texts = '_کاربر_ <code>@'..result.id_..'</code> _از گروه بن شد_'
		 chat_kick(msg.chat_id_, result.id_)
	end
            else 
            texts = '<code>این کاربر در گروه وجود ندارد</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],ban_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([bB][aA][nN]) (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([bB][aA][nN]) (%d+)$")}
	if is_mod(ap[2], msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_شما نمیتوانید افراد مقام دار را بن کنید!_', 1, 'md')
    else
	        database:sadd('bot:banned:'..msg.chat_id_, ap[2])
		 chat_kick(msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..ap[2]..'* _از گروه بن شد_', 1, 'md')
	end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([dD][eE][lL][aA][lL][Ll])$") and is_owner(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function delall_by_reply(extra, result, success)
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_شما نمیتوانید پیام افراد دارای مقام را پاک کنید_', 1, 'md')
    else
         send(msg.chat_id_, msg.id_, 1, '_تمامی پیام های کاربر _ *'..result.sender_user_id_..'* _حذف شد_', 1, 'md')
		     del_all_msgs(result.chat_id_, result.sender_user_id_)
    end
	end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,delall_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([dD][eE][lL][aA][lL][Ll]) (%d+)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
		local ass = {string.match(text, "^[#/!]([dD][eE][lL][aA][lL][Ll]) (%d+)$")} 
	if is_mod(ass[2], msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_شما نمیتوانید پیام افراد دارای مقام را پاک کنید_', 1, 'md')
    else
	 		     del_all_msgs(msg.chat_id_, ass[2])
         send(msg.chat_id_, msg.id_, 1, '_تمامی پیام های کاربر _  <code>'..ass[2]..'</code> _حذف شد_', 1, 'html')
    end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([dD][eE][lL][aA][lL][Ll]) @(.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([dD][eE][lL][aA][lL][Ll]) @(.*)$")} 
	function delall_by_username(extra, result, success)
	if result.id_ then
	if is_mod(result.id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_شما نمیتوانید پیام افراد دارای مقام را پاک کنید_', 1, 'md')
		 return false
    end
		 		     del_all_msgs(msg.chat_id_, result.id_)
            text = '_تمامی پیام های کاربر _ <code>'..result.id_..'</code> _حذف شد_'
            else 
            text = '<code>این کاربر در گروه یافت نشد</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	      resolve_username(ap[2],delall_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([uU][nN][bB][aA][nN])$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function unban_by_reply(extra, result, success)
	local hash = 'bot:banned:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _از قبل بن نشده است!_', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _با موفقیت آنبن شد_', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,unban_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([uU][nN][bB][aA][nN]) @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([uU][nN][bB][aA][nN]) @(.*)$")} 
	function unban_by_username(extra, result, success)
	if result.id_ then
         database:srem('bot:banned:'..msg.chat_id_, result.id_)
            text = '_کاربر_ <code>'..result.id_..'</code> _با موفقیت آنبن شد_'
            else 
            text = '<code>این کاربر در گروه یافت نشد!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	      resolve_username(ap[2],unban_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([uU][nN][bB][aA][nN]) (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([uU][nN][bB][aA][nN]) (%d+)$")} 	
	        database:srem('bot:banned:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..ap[2]..'* _با موفقیت آنبن شد_', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][mM][Uu][tT][eE][Uu][Ss][Ee][rR]$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function mute_by_reply(extra, result, success)
	local hash = 'bot:muted:'..msg.chat_id_
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_شما نمیتوانید مقام بالاتر از خود را موت کنید_', 1, 'md')
    else
    if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _از قبل در  لیست افراد سکوت بوده است_', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _به لیست افراد سکوت اضافه شد._', 1, 'md')
	end
    end
	end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,mute_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([mM][Uu][tT][eE][Uu][Ss][Ee][rR]) @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([mM][Uu][tT][eE][Uu][Ss][Ee][rR]) @(.*)$")} 
	function mute_by_username(extra, result, success)
	if result.id_ then
	if is_mod(result.id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_شما نمیتوانید مقام بالاتر از خود را موت کنید_', 1, 'md')
    else
	        database:sadd('bot:muted:'..msg.chat_id_, result.id_)
            texts = '_کاربر_ <code>'..result.id_..'</code> _به لیست افراد سکوت اضافه شد._'
		 chat_kick(msg.chat_id_, result.id_)
	end
            else 
            texts = '<code>کاربرمورد نظر در گروه یافت نشد!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],mute_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([mM][Uu][tT][eE][Uu][Ss][Ee][rR]) (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([mM][Uu][tT][eE][Uu][Ss][Ee][rR]) (%d+)$")}
	if is_mod(ap[2], msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_شما نمیتوانید مقام بالاتر از خود را موت کنید_', 1, 'md')
    else
	        database:sadd('bot:muted:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_کاربر_*'..ap[2]..'* _به لیست افراد سکوت اضافه شد.__', 1, 'md')
	end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([uU][nN][mM][Uu][tT][eE][Uu][Ss][Ee][rR])$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function unmute_by_reply(extra, result, success)
	local hash = 'bot:muted:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _از قبل به لیست افراد سکوت اضافه نشده بود._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _از لیست افراد سکوت حذف گردید._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,unmute_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([uU][nN][mM][Uu][tT][eE][Uu][Ss][Ee][rR]) @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([uU][nN][mM][Uu][tT][eE][Uu][Ss][Ee][rR]) @(.*)$")} 
	function unmute_by_username(extra, result, success)
	if result.id_ then
         database:srem('bot:muted:'..msg.chat_id_, result.id_)
            text = '_کاربر_ <code>'..result.id_..'</code> _از لیست افراد سکوت حذف گردید._'
            else 
            text = '<code>کاربرمورد نظر در گروه یافت نشد!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	      resolve_username(ap[2],unmute_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([uU][nN][mM][Uu][tT][eE][Uu][Ss][Ee][rR]) (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([uU][nN][mM][Uu][tT][eE][Uu][Ss][Ee][rR]) (%d+)$")} 	
	        database:srem('bot:muted:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..ap[2]..'* _از لیست افراد سکوت حذف گردید._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]setowner$") and is_admin(msg.sender_user_id_) and msg.reply_to_message_id_ then
	function setowner_by_reply(extra, result, success)
	local hash = 'bot:owners:'..msg.chat_id_
	if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _از قبل به مدیر کل گروه یافته بود._', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..result.sender_user_id_..'* _به مقام مدیر کل گروه ارتقاء یافت_', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,setowner_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]setowner @(.*)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](setowner) @(.*)$")} 
	function setowner_by_username(extra, result, success)
	if result.id_ then
	        database:sadd('bot:owners:'..msg.chat_id_, result.id_)
            texts = '_کاربر_ <code>'..result.id_..'</code> _به مقام مدیر کل گروه ارتقاء یافت_'
            else 
            texts = '<code>کاربرمورد نظر در گروه یافت نشد!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],setowner_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]setowner (%d+)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](setowner) (%d+)$")} 	
	        database:sadd('bot:owners:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_کاربر_ *'..ap[2]..'* _به مقام مدیر کل گروه ارتقاء یافت_', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]demowner$") and is_admin(msg.sender_user_id_) and msg.reply_to_message_id_ then
	function deowner_by_reply(extra, result, success)
	local hash = 'bot:owners:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is not Owner._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Removed from ownerlist._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,deowner_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]demowner @(.*)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:owners:'..msg.chat_id_
	local ap = {string.match(text, "^[#/!](demowner) @(.*)$")} 
	function remowner_by_username(extra, result, success)
	if result.id_ then
         database:srem(hash, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Removed from ownerlist</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],remowner_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]demowner (%d+)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:owners:'..msg.chat_id_
	local ap = {string.match(text, "^[#/!](demowner) (%d+)$")} 	
         database:srem(hash, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Removed from ownerlist._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]addadmin$") and is_sudo(msg) and msg.reply_to_message_id_ then
	function addadmin_by_reply(extra, result, success)
	local hash = 'bot:admins:'
	if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is Already Admin._', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Added to BlackPlus admins._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,addadmin_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]addadmin @(.*)$") and is_sudo(msg) then
	local ap = {string.match(text, "^[#/!](addadmin) @(.*)$")} 
	function addadmin_by_username(extra, result, success)
	if result.id_ then
	        database:sadd('bot:admins:', result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Added to BlackPlus admins.!</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],addadmin_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]addadmin (%d+)$") and is_sudo(msg) then
	local ap = {string.match(text, "^[#/!](addadmin) (%d+)$")} 	
	        database:sadd('bot:admins:', ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Added to BlackPlus admins._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]remadmin$") and is_sudo(msg) and msg.reply_to_message_id_ then
	function deadmin_by_reply(extra, result, success)
	local hash = 'bot:admins:'
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is not Admin._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Removed from Blackplus Admins!._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,deadmin_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]remadmin @(.*)$") and is_sudo(msg) then
	local hash = 'bot:admins:'
	local ap = {string.match(text, "^[#/!](remadmin) @(.*)$")} 
	function remadmin_by_username(extra, result, success)
	if result.id_ then
         database:srem(hash, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Removed from Blackplus Admins!</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],remadmin_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]remadmin (%d+)$") and is_sudo(msg) then
	local hash = 'bot:admins:'
	local ap = {string.match(text, "^[#/!](remadmin) (%d+)$")} 	
         database:srem(hash, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* Removed from Blackplus Admins!_', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([mM][oO][dD][lL][iI][sS][tT])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local hash =  'bot:mods:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>لیست مدیران گروه:</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "هیچ دستیار مدیری در گروه وجود ندارد"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([mM][uU][tT][eE][lL][iI][Ss][tT])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local hash =  'bot:muted:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>لیست افراد سکوت شده:</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "هیچ فردی در گروه در حالت سکوت وجود ندارد"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([Oo][wW][nN][Ee][rR])$") or text:match("^[#!/]([Oo][wW][nN][Ee][rR][lL][iI][sS][tT])$") and is_sudo(msg) then
    local hash =  'bot:owners:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>لیست مدیران کل گروه:</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "هیچ مدیر کلی در گروه وجود ندارد"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([bB][Aa][nN][Ll][Ii][Ss][tT])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local hash =  'bot:banned:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>لیست افراد بن شده:</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "هیچ فردی در گروه بن نشده است"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]adminlist$") and is_sudo(msg) then
    local hash =  'bot:admins:'
	local list = database:smembers(hash)
	local text = "BlackPlus Admins:\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "Bot Admins List is empty"
    end
    send(msg.chat_id_, msg.id_, 1, '`'..text..'`', 'md')
    end
	-----------------------------------------------------------------------------------------------
    if text:match("^[#!/]([iI][dD])$") and msg.reply_to_message_id_ ~= 0 then
      function id_by_reply(extra, result, success)
	  local user_msgs = database:get('user:msgs'..result.chat_id_..':'..result.sender_user_id_)
        send(msg.chat_id_, msg.id_, 1, "_آیدی شما_: `"..result.sender_user_id_.."`\n_تعداد پیام های ارسالی_ : `"..user_msgs.."`", 1, 'md')
        end
   getMessage(msg.chat_id_, msg.reply_to_message_id_,id_by_reply)
  end
  -----------------------------------------------------------------------------------------------
    if text:match("^[#!/]([Ii][Dd]) @(.*)$") then
	local ap = {string.match(text, "^[#/!]([Ii][Dd]) @(.*)$")} 
	function id_by_username(extra, result, success)
	if result.id_ then
	if is_sudo(result) then
	  t = 'مدیر کل ربات'
      elseif is_admin(result.id_) then
	  t = 'اددمین ربات'
      elseif is_owner(result.id_, msg.chat_id_) then
	  t = 'مدیر کل گروه'
      elseif is_mod(result.id_, msg.chat_id_) then
	  t = 'دستیار مدیر'
      else
	  t = 'فرد عادی'
	  end
            texts = '_یوزرنیم کاربر_ : `@'..ap[2]..'`\n_آیدی کاربر_ : `('..result.id_..')`\n_مقام کاربر_ : `'..t..'`'
            else 
            texts = '<code>کاربر یافت نشد!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'md')
    end
	      resolve_username(ap[2],id_by_username)
    end
    -----------------------------------------------------------------------------------------------
  if text:match("^[#!/]([kK][Ii][cC][kK])$") and msg.reply_to_message_id_ and is_mod(msg.sender_user_id_, msg.chat_id_) then
      function kick_reply(extra, result, success)
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_شما نمیتوانید مقام بالاتر از خود را ریمو کنید_', 1, 'md')
    else
        send(msg.chat_id_, msg.id_, 1, '_کاربر_ '..result.sender_user_id_..' _اخراج گردید_.', 1, 'html')
        chat_kick(result.chat_id_, result.sender_user_id_)
        end
	end
   getMessage(msg.chat_id_,msg.reply_to_message_id_,kick_reply)
    end
    -----------------------------------------------------------------------------------------------
  if text:match("^[#!/]inv$") and msg.reply_to_message_id_ and is_sudo(msg) then
      function inv_reply(extra, result, success)
           add_user(result.chat_id_, result.sender_user_id_, 5)
        end
   getMessage(msg.chat_id_, msg.reply_to_message_id_,inv_reply)
    end
	-----------------------------------------------------------------------------------------------
    if text:match("^[#!/]([iI][dD])$") and msg.reply_to_message_id_ == 0  then
local function getpro(extra, result, success)
local user_msgs = database:get('user:msgs'..msg.chat_id_..':'..msg.sender_user_id_)
   if result.photos_[0] then
            sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_,'_آیدی سوپرگروه_: '..msg.chat_id_..'\n_آیدی شما_: '..msg.sender_user_id_..'\n_تعداد پیام های ارسالی توسط شما_: '..user_msgs,msg.id_,msg.id_)
   else
      send(msg.chat_id_, msg.id_, 1, "_آیدی گروه_: `"..msg.chat_id_.."`\n_آیدی شما_: `"..msg.sender_user_id_.."`\n_تعداد پیام های ارسالی_ : `"..user_msgs.."`", 1, 'md')
   end
   end
   tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = msg.sender_user_id_,
    offset_ = 0,
    limit_ = 1
  }, getpro, nil)
	end
	-----------------------------------------------------------------------------------------------
    if text:match("^[#!/]profileme (%d+)$") and msg.reply_to_message_id_ == 0  then
		local pronumb = {string.match(text, "^[#/!](profileme) (%d+)$")} 
local function gpro(extra, result, success)
--vardump(result)
   if pronumb[2] == '1' then
   if result.photos_[0] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '2' then
   if result.photos_[1] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[1].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 2 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '3' then
   if result.photos_[2] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[2].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 3 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '4' then
      if result.photos_[3] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[3].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 4 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '5' then
   if result.photos_[4] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[4].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 5 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '6' then
   if result.photos_[5] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[5].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 6 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '7' then
   if result.photos_[6] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[6].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 7 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '8' then
   if result.photos_[7] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[7].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 8 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '9' then
   if result.photos_[8] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[8].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 9 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '10' then
   if result.photos_[9] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[9].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "_You Have'nt 10 Profile Photo!!_", 1, 'md')
   end
   else
      send(msg.chat_id_, msg.id_, 1, "*I just can get last 10 profile photos!:(*", 1, 'md')
   end
   end
   tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = msg.sender_user_id_,
    offset_ = 0,
    limit_ = pronumb[2]
  }, gpro, nil)
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([lL][oO][cC][kK]) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local lockkpt = {string.match(text, "^[#/!]([lL][oO][cC][kK]) (.*)$")} 
      if lockkpt[2] == "edit" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ادیت کردن پیام فعال شد_', 1, 'md')
         database:set('editmsg'..msg.chat_id_,'delmsg')
	  end
	  if lockkpt[2] == "cmds" then
         send(msg.chat_id_, msg.id_, 1, '_قفل دستورات ربات برای اعضای عادی فعال شد_', 1, 'md')
         database:set('bot:cmds'..msg.chat_id_,true)
      end
	  if lockkpt[2] == "bots" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ورود ربات ها فعال شد_', 1, 'md')
         database:set('bot:bots:mute'..msg.chat_id_,true)
      end
	  if lockkpt[2] == "flood" then
         send(msg.chat_id_, msg.id_, 1, '_قفل پیام مکرر فعال شد_', 1, 'md')
         database:del('anti-flood:'..msg.chat_id_)
	  end
	  if lockkpt[2] == "pin" then
         send(msg.chat_id_, msg.id_, 1, "_قفل پین کردن پیام در گروه فعال شد_", 1, 'md')
	     database:set('bot:pin:mute'..msg.chat_id_,true)
      end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([sS][eE][Tt][fF][lL][oO][oO][dD]) (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local floodmax = {string.match(text, "^[#/!]([sS][eE][Tt][fF][lL][oO][oO][dD]) (%d+)$")} 
	if tonumber(floodmax[2]) < 2 then
         send(msg.chat_id_, msg.id_, 1, '_عدد وارد شده پیش از حد میباشد باید بین_  _[2-99999]_ _باشد_', 1, 'md')
	else
    database:set('flood:max:'..msg.chat_id_,floodmax[2])
         send(msg.chat_id_, msg.id_, 1, '_حساسیت پیام مکرر تغییر یافت به :_ *'..floodmax[2]..'*', 1, 'md')
	end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([sS][eE][Tt][fF][lL][oO][oO][dD][tT][iI][mM][eE]) (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local floodt = {string.match(text, "^[#/!]([sS][eE][Tt][fF][lL][oO][oO][dD][tT][iI][mM][eE]) (%d+)$")} 
	if tonumber(floodt[2]) < 2 then
         send(msg.chat_id_, msg.id_, 1, '_عدد وارد شده پیش از حد میباشد باید بین_  _[2-99999]_ _باشد_', 1, 'md')
	else
    database:set('flood:time:'..msg.chat_id_,floodt[2])
         send(msg.chat_id_, msg.id_, 1, '_چک کردن پیام تغییر یافت به :_ *'..floodt[2]..'*', 1, 'md')
	end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([sS][hH][oO][wW]) ([eE][dD][Ii][tT])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_فعال شد_\nاز این پس اگر متنی ادیت شود متن قبل ادیت به نمایش در میاید', 1, 'md')
         database:set('editmsg'..msg.chat_id_,'didam')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([Uu][Nn][sS][hH][oO][wW]) ([eE][dD][Ii][tT])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_غیرفعال شد_\nاز این پس اگر متنی ادیت شود متن قبل ادیت به نمایش در نمیاید', 1, 'md')
         database:del('editmsg'..msg.chat_id_,'didam')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([sS][eE][tT][lL][iI][nN][kK])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_لینک گروه خود را ارسال کنید_', 1, 'md')
         database:get("bot:group:link"..msg.chat_id_, 'لینک ثبت نشده است!!\n_لینک جدید گروه خود را ارسال کنید_')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([lL][iI][nN][kK])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local link = database:get("bot:group:link"..msg.chat_id_)
	  if link then
         send(msg.chat_id_, msg.id_, 1, '<b>لینک گروه:</b>\n'..link, 1, 'html')
	  else
         send(msg.chat_id_, msg.id_, 1, '_لینک تنظیم نشده لطفا دستور /setlink را ارسال کنید_', 1, 'md')
	  end
 	end
	
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([wW][eE][lL][cC][oO][mM][eE]) ([oO][nN])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_خوش آمد گویی در گروه فعال گردید_', 1, 'md')
		 database:set("bot:welcome"..msg.chat_id_,true)
	end
	if text:match("^[#!/]([wW][eE][lL][cC][oO][mM][eE]) ([oO][Ff][fF])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_خوش آمد گویی در گروه غیرفعال گردید_', 1, 'md')
		 database:del("bot:welcome"..msg.chat_id_)
	end
	if text:match("^[#!/]([sS][eE][tT]) ([wW][eE][lL][cC][oO][mM][eE]) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local welcome = {string.match(text, "^[#/!]([sS][eE][tT]) ([wW][eE][lL][cC][oO][mM][eE]) (.*)$")} 
         send(msg.chat_id_, msg.id_, 1, '_خوش آمدیی تنظیم شد!_\nمتن خوش آمد گویی:\n\n`'..welcome[2]..'`', 1, 'md')
		 database:set('welcome:'..msg.chat_id_,welcome[2])
	end
	if text:match("^[#!/]([dD][eE][lL]) ([wW][eE][lL][cC][oO][mM][eE])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_خوش آمد گویی حذف گردید_', 1, 'md')
		 database:del('welcome:'..msg.chat_id_)
	end
	if text:match("^[#!/](get) ([wW][eE][lL][cC][oO][mM][eE])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local wel = database:get('welcome:'..msg.chat_id_)
	if wel then
         send(msg.chat_id_, msg.id_, 1, wel, 1, 'md')
    else
         send(msg.chat_id_, msg.id_, 1, 'Welcome msg not saved!', 1, 'md')
	end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]action (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local lockpt = {string.match(text, "^[#/!](action) (.*)$")} 
      if lockpt[2] == "typing" then
          sendaction(msg.chat_id_, 'Typing')
	  end
	  if lockpt[2] == "video" then
          sendaction(msg.chat_id_, 'RecordVideo')
	  end
	  if lockpt[2] == "voice" then
          sendaction(msg.chat_id_, 'RecordVoice')
	  end
	  if lockpt[2] == "photo" then
          sendaction(msg.chat_id_, 'UploadPhoto')
	  end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([fF][Ii][lL][tT][eE][Rr]) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local filters = {string.match(text, "^[#/!]([fF][Ii][lL][tT][eE][Rr]) + (.*)$")} 
    local name = string.sub(filters[2], 1, 50)
          database:hset('bot:filters:'..msg.chat_id_, name, 'filtered')
		  send(msg.chat_id_, msg.id_, 1, "_کلمه جدید فیلتر شد_\n> `"..name.."`", 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([Uu][Nn][fF][Ii][lL][tT][eE][Rr]) - (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local rws = {string.match(text, "^[#/!]([fF][Ii][lL][tT][eE][Rr]) - (.*)$")} 
    local name = string.sub(rws[2], 1, 50)
          database:hdel('bot:filters:'..msg.chat_id_, rws[2])
		  send(msg.chat_id_, msg.id_, 1, "_کلمه_ > `"..rws[2].."`\n_از لیست فیلتر کلمات حذف گردید_", 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([fF][Ii][lL][tT][eE][rR][lL][iI][sS][tT])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:filters:'..msg.chat_id_
      if hash then
         local names = database:hkeys(hash)
         local text = '_لیست کلمات فیلتر شده_ :\n\n'
    for i=1, #names do
      text = text..'> `'..names[i]..'`\n'
    end
	if #names == 0 then
       text = "_هیچ کلمه ای در این گروه فیلتر نشده است_"
    end
		  send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
       end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([bB][Rr][oO][aA][dD][cC][Aa][Ss][tT]) (.*)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
    local gps = database:scard("bot:groups") or 0
    local gpss = database:smembers("bot:groups") or 0
	local rws = {string.match(text, "^[#/!]([bB][Rr][oO][aA][dD][cC][Aa][Ss][tT]) (.*)$")} 
	for i=1, #gpss do
		  send(gpss[i], 0, 1, rws[2], 1, 'md')
    end
                   send(msg.chat_id_, msg.id_, 1, '*Done*\n_Your Msg Send to_ `'..gps..'` _Groups_', 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([Ss][tT][aA][tT][sS])$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
    local gps = database:scard("bot:groups")
	local users = database:scard("bot:userss")
    local allmgs = database:get("bot:allmsgs")
                   send(msg.chat_id_, msg.id_, 1, '_آمار ربات هم اکنون!_\n\n_تعداد گروه هایی که ربات مدیریت میکند: _ `'..gps..'`\n_ تعداد کاربرانی که به خصوصی ربات مراجعه کرده اند: _ `'..users..'`\n_تعداد پیام های دریافتی از گروه ها: _ `'..allmgs..'`', 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]([uU][nN][lL][oO][cC][kK]) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local unlockkpt = {string.match(text, "^[#/!]([uU][nN][lL][oO][cC][kK]) (.*)$")} 
      if unlockkpt[2] == "edit" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ادیت غیرفعال شد_', 1, 'md')
         database:del('editmsg'..msg.chat_id_)
      end
	  if unlockkpt[2] == "cmds" then
         send(msg.chat_id_, msg.id_, 1, '_قفل دستورات ربات غیرفال گردید و اعضای عادی میتوانند استفاده کنند_', 1, 'md')
         database:del('bot:cmds'..msg.chat_id_)
      end
	  if unlockkpt[2] == "bots" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ورود ربات ها غیرفعال شد_', 1, 'md')
         database:del('bot:bots:mute'..msg.chat_id_)
      end
	  if unlockkpt[2] == "flood" then
         send(msg.chat_id_, msg.id_, 1, '_قفل پیام مکرر غیرفعال شد_', 1, 'md')
         database:set('anti-flood:'..msg.chat_id_,true)
	  end
	  if unlockkpt[2] == "pin" then
         send(msg.chat_id_, msg.id_, 1, "_قفل پین کردن پیام غیرفال شد_", 1, 'md')
	     database:del('bot:pin:mute'..msg.chat_id_)
      end
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]mute all (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local mutept = {string.match(text, "^[#!/]mute all (%d+)$")}
	    		database:setex('bot:muteall'..msg.chat_id_, tonumber(mutept[1]), true)
         send(msg.chat_id_, msg.id_, 1, '_کل گروه در حالت سکوت به مدت_ *'..mutept[1]..'* _ثانیه انجام شد!_', 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]([mM][uU][tT][eE]) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local mutept = {string.match(text, "^[#/!]([mM][uU][tT][eE]) (.*)$")} 
      if mutept[2] == "all" then
         send(msg.chat_id_, msg.id_, 1, '_کل گروه در حالت سکوت قرار گرفت_', 1, 'md')
         database:set('bot:muteall'..msg.chat_id_,true)
      end
	  if mutept[2] == "text" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت متن فعال شد_', 1, 'md')
         database:set('bot:text:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "photo" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت عکس فعال شد_', 1, 'md')
         database:set('bot:photo:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "video" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت ویدِیو فعال شد_', 1, 'md')
         database:set('bot:video:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "gifs" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت گیف فعال شد_', 1, 'md')
         database:set('bot:gifs:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "music" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت موزیک فعال شد_', 1, 'md')
         database:set('bot:music:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "voice" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت ویس فعال شد_', 1, 'md')
         database:set('bot:voice:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "location" then
         send(msg.chat_id_, msg.id_, 1, ' _سکوت ارسال مکان فعال شد_', 1, 'md')
         database:set('bot:location:mute'..msg.chat_id_,true)
      end
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]([uU][Nn][Mm][Uu][Tt][Ee]) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local unmutept = {string.match(text, "^[#/!]([uU][Nn][Mm][Uu][Tt][Ee]) (.*)$")} 
      if unmutept[2] == "all" then
         send(msg.chat_id_, msg.id_, 1, '_گروه از حالت سکوت خارج گردید_', 1, 'md')
         database:del('bot:muteall'..msg.chat_id_)
      end
	  if unmutept[2] == "text" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت متن غیرفعال شد_', 1, 'md')
         database:del('bot:text:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "photo" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت عکس غیرفعال شد_', 1, 'md')
         database:del('bot:photo:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "video" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت ویدِیو غیرفعال شد_', 1, 'md')
         database:del('bot:video:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "gifs" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت گیف غیرغعال شد_', 1, 'md')
         database:del('bot:gifs:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "music" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت موزیک غیرفعال شد_ ', 1, 'md')
         database:del('bot:music:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "voice" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت ویس غیرفعال شد_', 1, 'md')
         database:del('bot:voice:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "location" then
         send(msg.chat_id_, msg.id_, 1, '_سکوت ارسال مکان غیرفعال شد_', 1, 'md')
         database:del('bot:location:mute'..msg.chat_id_)
      end 
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([lL][oO][cC][kK]) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local lockpt = {string.match(text, "^[#/!]([lL][oO][cC][kK]) (.*)$")} 
	  if lockpt[2] == "inline" then
         send(msg.chat_id_, msg.id_, 1, '_قفل اینلاین پیام فعال گردید_', 1, 'md')
         database:set('bot:inline:mute'..msg.chat_id_,true)
      end
	  if lockpt[2] == "links" then
         send(msg.chat_id_, msg.id_, 1, '_قفل لینک فعال شد_', 1, 'md')
         database:set('bot:links:mute'..msg.chat_id_,true)
      end
	  if lockpt[2] == "username" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال یوزرنیم(@) فعال شد_', 1, 'md')
         database:set('bot:tag:mute'..msg.chat_id_,true)
      end
	  if lockpt[2] == "hashtag" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال هشتگ(#) فعال شد_', 1, 'md')
         database:set('bot:hashtag:mute'..msg.chat_id_,true)
      end
	  if lockpt[2] == "contact" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال شماره تلفن فعال شد_', 1, 'md')
         database:set('bot:contact:mute'..msg.chat_id_,true)
      end
	  if lockpt[2] == "linkpro" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال لینک پیشرفته فعال شد_', 1, 'md')
         database:set('bot:webpage:mute'..msg.chat_id_,true)
      end
	   if lockpt[2] == "markdown" then
         send(msg.chat_id_, msg.id_, 1, '_قفل هایپرلینک و بولد و ایتالیک فعال شد_', 1, 'md')
         database:set('bot:markdown:mute'..msg.chat_id_,true)
      end
	  if lockpt[2] == "operator" then
         send(msg.chat_id_, msg.id_, 1, '_قفل اپراتور فعال شد_', 1, 'md')
         database:set('bot:operator:mute'..msg.chat_id_,true)
      end
	  if lockpt[2] == "arabic" then
         send(msg.chat_id_, msg.id_, 1, '_قفل زبان عربی و فارسی فعال شد_', 1, 'md')
         database:set('bot:arabic:mute'..msg.chat_id_,true)
      end
	  if lockpt[2] == "english" then
         send(msg.chat_id_, msg.id_, 1, '_قفل زبان انگلیسی فعال شد_', 1, 'md')
         database:set('bot:english:mute'..msg.chat_id_,true)
      end 
	  if lockpt[2] == "sticker" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال استیکر فعال شد_', 1, 'md')
         database:set('bot:sticker:mute'..msg.chat_id_,true)
      end 
	  if lockpt[2] == "service" then
         send(msg.chat_id_, msg.id_, 1, '_قفل پیام ورود و خروج فعال شد_', 1, 'md')
         database:set('bot:tgservice:mute'..msg.chat_id_,true)
      end
	  if lockpt[2] == "forward" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال پیام فروراد فعال شد_', 1, 'md')
         database:set('bot:forward:mute'..msg.chat_id_,true)
      end
	end
    -----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([uU][nN][lL][oO][cC][kK]) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local unlockpt = {string.match(text, "^[#/!]([uU][nN][lL][oO][cC][kK]) (.*)$")} 
	  if unlockpt[2] == "links" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال لینک غیرفعال شد_', 1, 'md')
         database:del('bot:links:mute'..msg.chat_id_)
      end
	  if unlockpt[2] == "username" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال یوزرنیم(@) غیرفعال شد_', 1, 'md')
         database:del('bot:tag:mute'..msg.chat_id_)
      end
	  if unlockpt[2] == "hashtag" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال هشتگ(#) غیرفعال شد_', 1, 'md')
         database:del('bot:hashtag:mute'..msg.chat_id_)
      end
	  if unlockpt[2] == "contact" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال شماره تلفن غیرفعال شد_', 1, 'md')
         database:del('bot:contact:mute'..msg.chat_id_)
      end
	  if unlockpt[2] == "linkpro" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال لینک پیشرفته غیرفعال شد_', 1, 'md')
         database:del('bot:webpage:mute'..msg.chat_id_)
      end
	   if unlockpt[2] == "operator" then
         send(msg.chat_id_, msg.id_, 1, '_قفل اپراتور غیرفعال شد_', 1, 'md')
         database:del('bot:operator:mute'..msg.chat_id_)
      end
	   if unlockpt[2] == "markdown" then
         send(msg.chat_id_, msg.id_, 1, '_قفل هایپرلینک و بولد و ایتالیک غیرفعال شد_', 1, 'md')
         database:del('bot:markdown:mute'..msg.chat_id_)
      end
	  if unlockpt[2] == "arabic" then
         send(msg.chat_id_, msg.id_, 1, '_قفل زبان فارسی و عربی غیرفعال شد_', 1, 'md')
         database:del('bot:arabic:mute'..msg.chat_id_)
      end
	  if unlockpt[2] == "english" then
         send(msg.chat_id_, msg.id_, 1, '_قفل زبان انگلیسی غیرفعال شد_', 1, 'md')
         database:del('bot:english:mute'..msg.chat_id_)
      end
	  if unlockpt[2] == "service" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ورود و خروج غیرفعال شد_', 1, 'md')
         database:del('bot:tgservice:mute'..msg.chat_id_)
      end
	  if unlockpt[2] == "sticker" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال استیکر غیرفعال شد_', 1, 'md')
         database:del('bot:sticker:mute'..msg.chat_id_)
      end
	  if unlockpt[2] == "forward" then
         send(msg.chat_id_, msg.id_, 1, '_قفل ارسال پیام فروراد غیرفعال شد_', 1, 'md')
         database:del('bot:forward:mute'..msg.chat_id_)
      end 
	end
    -----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]([eE][dD][iI][tT]) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local editmsg = {string.match(text, "^[#/!](edit) (.*)$")} 
		 edit(msg.chat_id_, msg.reply_to_message_id_, nil, editmsg[2], 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]user$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	          send(msg.chat_id_, msg.id_, 1, '*'..from_username(msg)..'*', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]([cC][lL][eE][aA][nN]) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!]([cC][lL][eE][aA][nN]) (.*)$")} 
       if txt[2] == 'banlist' then
	      database:del('bot:banned:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_تمامی افراد بن شده به حالت آنبن در آمدند_', 1, 'md')
       end
	   if txt[2] == 'bots' then
	  local function g_bots(extra,result,success)
      local bots = result.members_
      for i=0 , #bots do
          chat_kick(msg.chat_id_,bots[i].user_id_)
          end
      end
    channel_get_bots(msg.chat_id_,g_bots)
	          send(msg.chat_id_, msg.id_, 1, '_تمامی ربات های موجود در این گروه بن گردید_', 1, 'md')
	end
	   if txt[2] == 'modlist' then
	      database:del('bot:mods:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_تمامی دستیار مدیران حذف گردید و کاربر عادی شدند_', 1, 'md')
       end
	   if txt[2] == 'filterlist' then
	      database:del('bot:filters:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_فیلتر تمامی کلمات حذف گردید_', 1, 'md')
       end
	   if txt[2] == 'mutelist' then
	      database:del('bot:muted:'..msg.chat_id_)
             send(msg.chat_id_, msg.id_, 1, '_لیست افراد سکوت شده پاکسازی شدند_', 1, 'md')
       end
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]([sS][Ee][tT][tT][iI][nN][gG][sS])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	if database:get('bot:muteall'..msg.chat_id_) then
	mute_all = 'Mute'
	else
	mute_all = 'UnMute'
	end
	------------
	if database:get('bot:text:mute'..msg.chat_id_) then
	mute_text = 'Mute'
	else
	mute_text = 'UnMute'
	end
	------------
	if database:get('bot:photo:mute'..msg.chat_id_) then
	mute_photo = 'Mute'
	else
	mute_photo = 'UnMute'
	end
	------------
	if database:get('bot:video:mute'..msg.chat_id_) then
	mute_video = 'Mute'
	else
	mute_video = 'UnMute'
	end
	------------
	if database:get('bot:gifs:mute'..msg.chat_id_) then
	mute_gifs = 'Mute'
	else
	mute_gifs = 'UnMute'
	end
	------------
	if database:get('anti-flood:'..msg.chat_id_) then
	mute_flood = 'Unlock'
	else
	mute_flood = 'Lock'
	end
	------------
	if not database:get('flood:max:'..msg.chat_id_) then
	flood_m = 5
	else
	flood_m = database:get('flood:max:'..msg.chat_id_)
	end
	------------
	if not database:get('flood:time:'..msg.chat_id_) then
	flood_t = 3
	else
	flood_t = database:get('flood:time:'..msg.chat_id_)
	end
	------------
	if database:get('bot:music:mute'..msg.chat_id_) then
	mute_music = 'Mute'
	else
	mute_music = 'UnMute'
	end
	------------
	if database:get('bot:bots:mute'..msg.chat_id_) then
	mute_bots = 'Lock'
	else
	mute_bots = 'Unlock'
	end
	------------
	if database:get('bot:inline:mute'..msg.chat_id_) then
	mute_in = 'Lock'
	else
	mute_in = 'Unlock'
	end
	------------
	if database:get('bot:cmds'..msg.chat_id_) then
	mute_cmd = 'Lock'
	else
	mute_cmd = 'UnLock'
	end
	------------
	if database:get('bot:voice:mute'..msg.chat_id_) then
	mute_voice = 'Mute'
	else
	mute_voice = 'UnMute'
	end
	------------
	if database:get('editmsg'..msg.chat_id_) then
	mute_edit = 'Lock'
	else
	mute_edit = 'Unlock'
	end
    ------------
	if database:get('bot:links:mute'..msg.chat_id_) then
	mute_links = 'Lock'
	else
	mute_links = 'Unlock'
	end
    ------------
	if database:get('bot:pin:mute'..msg.chat_id_) then
	lock_pin = 'Lock'
	else
	lock_pin = 'Unlock'
	end 
    ------------
	if database:get('bot:sticker:mute'..msg.chat_id_) then
	lock_sticker = 'Lock'
	else
	lock_sticker = 'Unlock'
	end
	------------
    if database:get('bot:tgservice:mute'..msg.chat_id_) then
	lock_tgservice = 'Lock'
	else
	lock_tgservice = 'Unlock'
	end
	------------
    if database:get('bot:webpage:mute'..msg.chat_id_) then
	lock_wp = 'Lock'
	else
	lock_wp = 'Unlock'
	end
	------------
    if database:get('bot:hashtag:mute'..msg.chat_id_) then
	lock_htag = 'Lock'
	else
	lock_htag = 'Unlock'
	end
	------------
    if database:get('bot:tag:mute'..msg.chat_id_) then
	lock_tag = 'Lock'
	else
	lock_tag = 'Unlock'
	end
	------------
    if database:get('bot:location:mute'..msg.chat_id_) then
	lock_location = 'Mute'
	else
	lock_location = 'UnMute'
	end
	------------
    if database:get('bot:contact:mute'..msg.chat_id_) then
	lock_contact = 'Lock'
	else
	lock_contact = 'Unlock'
	end
	------------
	if database:get('bot:operator:mute'..msg.chat_id_) then
	lock_operator = 'Lock'
	else
	lock_operator = 'Unlock'
	end
	------------
    if database:get('bot:english:mute'..msg.chat_id_) then
	lock_english = 'Lock'
	else
	lock_english = 'Unlock'
	end
	------------
    if database:get('bot:arabic:mute'..msg.chat_id_) then
	lock_arabic = 'Lock'
	else
	lock_arabic = 'Unlock'
	end
	------------
    if database:get('bot:forward:mute'..msg.chat_id_) then
	lock_forward = 'Lock'
	else
	lock_forward = 'Unlock'
	end
	------------
	if database:get('bot:markdown:mute'..msg.chat_id_) then
	lock_markdown = 'Lock'
	else
	lock_markdown = 'Unlock'
	end
	------------
	if database:get("bot:welcome"..msg.chat_id_) then
	send_welcome = 'Enable'
	else
	send_welcome = 'Disable'
	end
	------------
	local ex = database:ttl("bot:charge:"..msg.chat_id_)
                if ex == -1 then
				exp_dat = 'Unlimited'
				else
				exp_dat = math.floor(ex / 86400) + 1
			    end
 	------------
	local TXT = "*SuperGroup Settings:*\n*------------------------------*\n"
	          .."*Lock Links* --> `"..mute_links.."`\n"
			  .."*Lock TgService* --> `"..lock_tgservice.."`\n"
	          .."*Lock LinkPro* --> `"..lock_wp.."`\n"
			  .."*Lock Cmds* --> `"..mute_cmd.."`\n"
	          .."*Lock Username(@)* --> `"..lock_tag.."`\n"
	          .."*Lock Hashtag(#)* --> `"..lock_htag.."`\n"
	          .."*Lock Contact* --> `"..lock_contact.."`\n"
	          .."*Lock English* --> `"..lock_english.."`\n"
			  .."*Lock Operator* --> `"..lock_operator.."`\n" 
              .."*Lock Markdown* --> `"..lock_markdown.."`\n"
			  .."*Lock Sticker* --> `"..lock_sticker.."`\n"
	          .."*Lock Bots* --> `"..mute_bots.."`\n"
	          .."*Lock Inline* --> `"..mute_in.."`\n"
	          .."*Lock Arabic* --> `"..lock_arabic.."`\n"
	          .."*Lock Forward* --> `"..lock_forward.."`\n"
	          .."*Lock Edit* --> `"..mute_edit.."`\n"
	          .."*Lock Pin* --> `"..lock_pin.."`\n"
	          .."*Lock Flood* --> `"..mute_flood.."`\n"
	          .."*------------------------------*\n"
	          .."*MuteList Settings:*\n\n"
	          .."*Mute all* --> `"..mute_all.."`\n"
	          .."*Mute Text* --> `"..mute_text.."`\n"
	          .."*Mute Photo* --> `"..mute_photo.."`\n"
	          .."*Mute Video* --> `"..mute_video.."`\n"
			  .."*Mute Location* --> `"..lock_location.."`\n"
	          .."*Mute Gifs* --> `"..mute_gifs.."`\n"
	          .."*Mute Music* --> `"..mute_music.."`\n"
	          .."*Mute Voice* --> `"..mute_voice.."`\n"
	          .."*------------------------------*\n"
			  .."*Group Welcome* --> `"..send_welcome.."`\n"
			  .."*Flood Sensitivity* --> `"..flood_m.."`\n"
	          .."*Flood Time* --> `"..flood_t.."`\n"
	          .."*ExpireTime Group* --> `"..exp_dat.."`\n"
         send(msg.chat_id_, msg.id_, 1, TXT, 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]echo (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!](echo) (.*)$")} 
         send(msg.chat_id_, msg.id_, 1, txt[2], 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]([sS][eE][tT][rR][Uu][lL][eE][sS]) (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!]([sS][eE][tT][rR][Uu][lL][eE][sS]) (.*)$")}
	database:set('bot:rules'..msg.chat_id_, txt[2])
         send(msg.chat_id_, msg.id_, 1, '_قوانین گروه ثبت شد_', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]([rR][Uu][lL][eE][sS])$") then
	local rules = database:get('bot:rules'..msg.chat_id_)
         send(msg.chat_id_, msg.id_, 1, rules, 1, nil)
    end
        ----------------------------------------------------------------------------------------------
	if text:match("^[#!/]reload$") and is_sudo(msg) then
	reload()
         send(msg.chat_id_, msg.id_, 1, '*Reloaded*', 1, 'md') 
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]([rR][eE][nN][Aa][mM][eE]) (.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!]([rR][eE][nN][Aa][mM][eE]) (.*)$")} 
	     changetitle(msg.chat_id_, txt[2])
         send(msg.chat_id_, msg.id_, 1, '_نام گروه با موفقیت تغییر کرد._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]getme$") then
	function guser_by_reply(extra, result, success)
         --vardump(result)
    end
	     getUser(msg.sender_user_id_,guser_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]setphoto$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_Please send a photo noew!_', 1, 'md')
		 database:set('bot:setphoto'..msg.chat_id_..':'..msg.sender_user_id_,true)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]charge (%d+)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
		local a = {string.match(text, "^[#/!](charge) (%d+)$")} 
         send(msg.chat_id_, msg.id_, 1, '_این گروه به مدت_ *'..a[2]..'* _روز شارژ شد_', 1, 'md')
		 local time = a[2] * day
         database:setex("bot:charge:"..msg.chat_id_,time,true)
		 database:set("bot:enable:"..msg.chat_id_,true)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]charge stats") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local ex = database:ttl("bot:charge:"..msg.chat_id_)
       if ex == -1 then
		send(msg.chat_id_, msg.id_, 1, '_انقضای گروه شما نامحدود میباشد_', 1, 'md')
       else
        local d = math.floor(ex / day ) + 1
	   		send(msg.chat_id_, msg.id_, 1, d.." روز تا انقضای گروه باقی مانده است", 1, 'md')
       end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]charge stats (%d+)") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!](charge stats) (%d+)$")} 
    local ex = database:ttl("bot:charge:"..txt[2])
       if ex == -1 then
		send(msg.chat_id_, msg.id_, 1, '_نامحدود!_', 1, 'md')
       else
        local d = math.floor(ex / day ) + 1
	   		send(msg.chat_id_, msg.id_, 1, d.." روز تا انقضا گروه باقی مانده", 1, 'md')
       end
    end
	-----------------------------------------------------------------------------------------------
	 if is_sudo(msg) then
  -----------------------------------------------------------------------------------------------
  if text:match("^[#!/]leave(-%d+)") and is_admin(msg.sender_user_id_, msg.chat_id_) then
  	local txt = {string.match(text, "^[#/!](leave)(-%d+)$")} 
	   send(msg.chat_id_, msg.id_, 1, 'ربات با موفقیت از گروه '..txt[2]..' خارج شد.', 1, 'md')
	   send(txt[2], 0, 1, 'ربات به دلایلی گروه را ترک میکند\nبرای اطلاعات بیشتر میتوانید با @MohammadNBG در ارتباط باشید.\nدر صورت ریپورت بودن میتوانید با ربات زیر به ما پیام دهید\n@MohammadNBGBot\n\nChannel> @IRANDEVTEAM', 1, 'html')
	   chat_leave(txt[2], bot_id)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[#!/]plan1(-%d+)') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!](plan1)(-%d+)$")} 
       local timeplan1 = 2592000
       database:setex("bot:charge:"..txt[2],timeplan1,true)
	   send(msg.chat_id_, msg.id_, 1, 'پلن 1 با موفقیت برای گروه '..txt[2]..' فعال شد\nاین گروه تا 30 روز دیگر اعتبار دارد! ( 1 ماه )', 1, 'md')
	   send(txt[2], 0, 1, 'ربات با موفقیت فعال شد و تا 30 روز دیگر اعتبار دارد!', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*User "..msg.sender_user_id_.." Added bot to new group*" , 1, 'md')
       end
	   database:set("bot:enable:"..txt[2],true)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[#!/]plan2(-%d+)') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!](plan2)(-%d+)$")} 
       local timeplan2 = 7776000
       database:setex("bot:charge:"..txt[2],timeplan2,true)
	   send(msg.chat_id_, msg.id_, 1, 'پلن 2 با موفقیت برای گروه '..txt[2]..' فعال شد\nاین گروه تا 90 روز دیگر اعتبار دارد! ( 3 ماه )', 1, 'md')
	   send(txt[2], 0, 1, 'ربات با موفقیت فعال شد و تا 90 روز دیگر اعتبار دارد!', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*User  "..msg.sender_user_id_.." Added bot to new group*" , 1, 'md')
       end
	   database:set("bot:enable:"..txt[2],true)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[#!/]plan3(-%d+)') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!](plan3)(-%d+)$")} 
       database:set("bot:charge:"..txt[2],true)
	   send(msg.chat_id_, msg.id_, 1, 'پلن 3 با موفقیت برای گروه '..txt[2]..' فعال شد\nاین گروه به صورت نامحدود شارژ شد!', 1, 'md')
	   send(txt[2], 0, 1, 'ربات بدون محدودیت فعال شد ! ( نامحدود )', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*User  "..msg.sender_user_id_.." Added bot to new group*" , 1, 'md')
       end
	   database:set("bot:enable:"..txt[2],true)
  end
  -----------------------------------------------------------------------------------------------
 if text:match('^[#!/]add') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!](add)$")} 
       database:set("bot:charge:"..msg.chat_id_,true)
	   send(msg.chat_id_, msg.id_, 1, 'گروه به دیتابیس اضافه شد!', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*کاربر "..msg.sender_user_id_.." ربات را در گروه جدید ادد کرد*" , 1, 'md')
       end
	   database:set("bot:enable:"..msg.chat_id_,true)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[#!/]rem') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!](rem)$")} 
       database:del("bot:charge:"..msg.chat_id_)
	   send(msg.chat_id_, msg.id_, 1, 'گروه از دیتابیس حذف شد!', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*کاربر "..msg.sender_user_id_.." ربات را در گروه حذف کرد*" , 1, 'md')
       end
  end
  -----------------------------------------------------------------------------------------------
   if text:match('[#/!]join(-%d+)') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!](join)(-%d+)$")} 
	   send(msg.chat_id_, msg.id_, 1, 'با موفقیت تورو به گروه '..txt[2]..' اضافه کردم.', 1, 'md')
	   send(txt[2], 0, 1, 'مدیر ربات وارد گروه میشود لطفا احترام خود را با مدیر ربات حفظ کنید با تشکر!🌚', 1, 'md')
	   add_user(txt[2], msg.sender_user_id_, 10)
  end
   -----------------------------------------------------------------------------------------------
  end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]del (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
       local delnumb = {string.match(text, "^[#/!](del) (%d+)$")} 
	   if tonumber(delnumb[2]) > 100 then
			send(msg.chat_id_, msg.id_, 1, 'Error\nuse /del [1-100]', 1, 'md')
else
       local id = msg.id_ - 1
        for i= id - delnumb[2] , id do 
        delete_msg(msg.chat_id_,{[0] = i})
        end
			send(msg.chat_id_, msg.id_, 1, 'our '..delnumb[2]..' Has Been Removed.', 1, 'md')
    end
	end
	-----------------------------------------------------------------------------------------------
   if text:match("^[#!/]([mM][eE])$") then
      if is_sudo(msg) then
	  t = 'مدیر کل ربات'
      elseif is_admin(msg.sender_user_id_) then
	  t = 'اددمین ربات'
      elseif is_owner(msg.sender_user_id_, msg.chat_id_) then
	  t = 'مدیر کل گروه'
      elseif is_mod(msg.sender_user_id_, msg.chat_id_) then
	  t = 'دستیار مدیر'
      else
	  t = 'اعضای عادی'
	  end
         send(msg.chat_id_, msg.id_, 1, '_یوزرنیم شما_ : @'..msg.sender_user_username_..'\n_مقام شما_: '..t, 1, 'md')
    end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/]([pp][ii][nn])$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
       pin(msg.chat_id_,msg.reply_to_message_id_,0)
	   database:set('pinnedmsg'..msg.chat_id_,msg.reply_to_message_id_)
	      send(msg.chat_id_, msg.id_, 1, '_پیام مورد نظر سنجاق گردید_', 1, 'md')
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/]([uu][nn][pp][ii][nn])$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
         unpinmsg(msg.chat_id_)
         send(msg.chat_id_, msg.id_, 1, '_پیام از  حالت سنجاق حذف گردید_', 1, 'md')
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/]repin$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
local pin_id = database:get('pinnedmsg'..msg.chat_id_)
        if pin_id then
         pin(msg.chat_id_,pin_id,0)
         send(msg.chat_id_, msg.id_, 1, '*Last Pinned msg has been repinned!*', 1, 'md')
		else
         send(msg.chat_id_, msg.id_, 1, "*i Can't find last pinned msgs...*", 1, 'md')
		 end
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/]viewpost$") then
        database:set('bot:viewget'..msg.sender_user_id_,true)
        send(msg.chat_id_, msg.id_, 1, '_پست مورد نظر را فروراد کنید_', 1, 'md')
   end
  end
  -----------------------------------------------------------------------------------------------
 end
  -----------------------------------------------------------------------------------------------
                                       -- end code --
  -----------------------------------------------------------------------------------------------
  elseif (data.ID == "UpdateChat") then
    chat = data.chat_
    chats[chat.id_] = chat
  -----------------------------------------------------------------------------------------------
  elseif (data.ID == "UpdateMessageEdited") then
   local msg = data
  -- vardump(msg)
  	function get_msg_contact(extra, result, success)
	local text = (result.content_.text_ or result.content_.caption_)
    --vardump(result)
	if result.id_ and result.content_.text_ then
	database:set('bot:editid'..result.id_,result.content_.text_)
	end
  if not is_mod(result.sender_user_id_, result.chat_id_) then
   check_filter_words(result, text)
   if text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") or text:match("[Tt][Mm].[Mm][Ee]") or text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Dd][Oo][Gg]") then
   if database:get('bot:links:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   	if text:match("[Hh][Tt][Tt][Pp][Ss]://") or text:match("[Hh][Tt][Tt][Pp]://") or text:match(".[Ii][Rr]") or text:match(".[Cc][Oo][Mm]") or text:match(".[Oo][Rr][Gg]") or text:match(".[Ii][Nn][Ff][Oo]") or text:match("[Ww][Ww][Ww].") or text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   if text:match("@") then
   if database:get('bot:tag:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
     if text:match("شارژ") or text:match("همراه اول") or text:match("ایرانسل") or text:match("کد") or text:match("رایگان") or text:match("همراه") then
   if database:get('bot:operator:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   	if text:match("#") then
   if database:get('bot:hashtag:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   	if text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   if text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
    end
	end
	if database:get('editmsg'..msg.chat_id_) == 'delmsg' then
        local id = msg.message_id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
              delete_msg(chat,msgs)
	elseif database:get('editmsg'..msg.chat_id_) == 'didam' then
	if database:get('bot:editid'..msg.message_id_) then
		local old_text = database:get('bot:editid'..msg.message_id_)
	    send(msg.chat_id_, msg.message_id_, 1, '_چرا ادیت میکنی😠\nمن دیدم که گفتی:_\n\n*'..old_text..'*', 1, 'md')
	end
	end
    getMessage(msg.chat_id_, msg.message_id_,get_msg_contact)
  -----------------------------------------------------------------------------------------------
  elseif (data.ID == "UpdateOption" and data.name_ == "my_id") then
    tdcli_function ({ID="GetChats", offset_order_="9223372036854775807", offset_chat_id_=0, limit_=20}, dl_cb, nil)    
  end
  -----------------------------------------------------------------------------------------------
end
