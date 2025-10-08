return {
  "mfussenegger/nvim-dap",
  lazy = true,
  config = function()
    require('dap').adapters.java = {
      type = 'executable',
      command = 'jdb',
      args = { '-connect', 'com.sun.jdi.SocketAttach:hostname=localhost,port=5010' }
    }
    require('dap').configurations.clojure = {
      {
        type = 'java',
        request = 'attach',
        name = "Attach to Clojure REPL",
        hostName = "localhost",
        port = 5010,
      }
    }
  end
}
