require "json"

module LSP::Data
  enum MessageType
    Error   = 1
    Warning = 2
    Info    = 3
    Log     = 4
  end
end
