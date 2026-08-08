vim.opt.runtimepath:prepend(vim.fn.getcwd())

if vim.env.NVIM_WORKTRUNK_COVERAGE == "1" then
  require("luacov")
end

vim.cmd("runtime plugin/worktrunk.lua")
