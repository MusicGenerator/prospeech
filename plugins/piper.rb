require 'shellwords'
class Piper < Plugin

def init(init)
    super
    logger("INFO: INIT plugin #{self.class.name}.")
    @locked = -1          # Identifies if bot is locked to a user or not (-1) Contains a ID which could varies between sessions!
    @actor = -1           # User-Server ID for locking bot to a user
    @whisper = -1         # Used to whisper audio to a mumble client (future)
    @writetoch = -1       # All Messages that are written to the bot and not to the channel 

    @@bot[:bot] = self
    return @@bot
  end

  def name
    if  !@@bot[:bot].nil?
      self.class.name
    end
  end

  def help(h)
    h << "<hr><b>.myvoice</b> Take Bot as your voice.<" 
        +""
  end

  def handle_user_state_change(msg)
    logger("handler.actor #{msg.session} / saved.actor #{@actor}")
    if (@locked != -1) && (msg.session == @actor) && (msg.channel_id != "")
      logger "UserMoving to ChannelID: #{msg.channel_id}"
      @@bot[:cli].join_channel(msg.channel_id)
      if (@writetoch != -1) then 
        @writetoch = msg.channel_id
      end
    end
  end

  def handle_chat(msg, message)
    super
    if (message == "myvoice") && (@locked == -1)
      logger(message)
      @locked = msg.user_id
      @actor = msg.actor
      @@bot[:cli].text_user(msg.actor,"Bot spricht für Dich und folgt Dir!")
      @@bot[:cli].set_comment("Ich bin #{msg.username}'s Sprecher.")
      logger("userid #{@locked} locked")
    end

    if (@locked == msg.user_id)
      if (message == "notmyvoice")
        logger(message)
         @locked = -1
        @actor = -1
        @@bot[:cli].text_user(msg.actor, "Bot ist wieder frei für andere Benutzer, wenn Du der einzige Benutzer am Server bist ist ein .notmyvoice nicht mehr notwendig")
        @@bot[:cli].set_comment('MR-Bot Thorsten (sorry not fully functional yet)')
        logger("actor #{msg.user_id} unlocked")
      end
    
      if (message == "texttochannel")
        @writetoch = msg.channel_id
      end

      if (message == "notext")
        @writetoch = -1
      end
      logger("actor #{msg.actor} / session #{msg.session} / channel_id #{msg.channel_id} / tree_id #{msg.tree_id}")
    end
  end

  def handle_raw_input(msg)
    if (@@bot[:cli].users[msg.actor].user_id == @locked)
      @actor = msg.actor            # Update actor ID on every message because relogging gives an other ID and Channel-Following don't work without correct ID
      if ( @writetoch != -1 ) && (msg.session != nil)
        @@bot[:cli].send_text_message(channel_id: [@writetoch], message: msg.message)
      end
      nachricht = Shellwords.escape(msg.message)
      `echo #{nachricht} | #{Conf.gvalue("plugin:piper:exe_path")}piper --samlpe_rate 48000 #{Conf.gvalue("plugin:piper:options")} --output_file #{Conf.gvalue("plugin:piper:data_path")}say.wav` 
      `sox #{Conf.gvalue("plugin:piper:data_path")}say.wav -r 48000 #{Conf.gvalue("plugin:piper:data_path")}say2.wav`
      @@bot[:cli].player.play_file(Conf.gvalue("plugin:piper:data_path")+'say2.wav')
    end
end
end
