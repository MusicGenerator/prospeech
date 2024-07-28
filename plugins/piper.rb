require 'shellwords'
class Piper < Plugin

def init(init)
    super
    logger("INFO: INIT plugin #{self.class.name}.")
    @locked = -1

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

  def handle_chat(msg, message)
    super
    logger(message)
    if (message == "myvoice") && (@locked == -1)
      @locked = msg.user_id
      logger("userid #{@locked} locked")
    end

    if (message == "notmyvoice") && (@locked == msg.user_id)
      @locked = -1
      logger("actor #{userid} unlocked")
    end

  end

  def handle_raw_input(msg)
    logger(msg.actor)
    if (msg.actor == @locked)
      nachricht = Shellwords.escape(msg.message)
      `echo #{nachricht} | #{Conf.gvalue("plugin:piper:exe_path")}piper --samlpe_rate 48000 #{Conf.gvalue("plugin:piper:options")} --output_file #{Conf.gvalue("plugin:piper:data_path")}say.wav` 
      `sox #{Conf.gvalue("plugin:piper:data_path")}say.wav -r 48000 #{Conf.gvalue("plugin:piper:data_path")}say2.wav`
      @@bot[:cli].player.play_file(Conf.gvalue("plugin:piper:data_path")+'say2.wav')
    end
end
end
