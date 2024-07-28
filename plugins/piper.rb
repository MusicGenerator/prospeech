require 'shellwords'
class Piper < Plugin

def init(init)
    super
    logger("INFO: INIT plugin #{self.class.name}.")
    @locked = -1
    @actor = -1

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
    if (@locked != -1) && (msg.actor) && (msg.channel_id != "")
      logger "UserMoving to ChannelID: #{msg.channel_id}"
      @@bot[:cli].join_channel(msg.channel_id)
    end
  end

  def handle_chat(msg, message)
    super
    if (message == "myvoice") && (@locked == -1)
      logger(message)
      @locked = msg.user_id
      @actor = msg.actor
      logger("userid #{@locked} locked")
    end

    if (message == "notmyvoice") && (@locked == msg.user_id)
      logger(message)
      @locked = -1
      @actor = -1
      logger("actor #{userid} unlocked")
    end

  end

  def handle_raw_input(msg)
    if (msg.user_id == @locked)
      @actor = msg.actor            # Update actor ID on every message because relogging gives an other ID and Channel-Following don't work without correct ID
      nachricht = Shellwords.escape(msg.message)
      `echo #{nachricht} | #{Conf.gvalue("plugin:piper:exe_path")}piper --samlpe_rate 48000 #{Conf.gvalue("plugin:piper:options")} --output_file #{Conf.gvalue("plugin:piper:data_path")}say.wav` 
      `sox #{Conf.gvalue("plugin:piper:data_path")}say.wav -r 48000 #{Conf.gvalue("plugin:piper:data_path")}say2.wav`
      @@bot[:cli].player.play_file(Conf.gvalue("plugin:piper:data_path")+'say2.wav')
    end
end
end
