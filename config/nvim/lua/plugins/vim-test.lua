return {
  "vim-test/vim-test",
  cmd = { "TestFile", "TestNearest", "TestSuite", "TestLast" },
  init = function()
    vim.cmd([[let test#strategy = "toggleterm"]])
    vim.cmd([[let test#javascript#playwright#options = "--headed --retries 0 --workers 1"]])
    vim.cmd([[let test#clojure#runner = "leintest"]])
    vim.cmd([[let test#clojure#leintest#executable = "lein with-profile test midje"]])
    vim.cmd([[let test#clojure#leintest#options = ""]])
  end
}
