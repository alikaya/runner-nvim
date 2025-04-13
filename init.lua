local M = {}
local running_commands = {}
local Job = require('plenary.job')
local telescope = require('telescope.builtin')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local Path = require('plenary.path')

local commands_file = string.format('%s/runner_commands.json', vim.fn.stdpath('data'))

local default_commands = {
  -- { name = 'Command Name', cmd = 'echo "Hello, world!' }
}

local function load_commands()
    local path = Path:new(commands_file)
    if not path:exists() then
        return default_commands
    end

    local content = path:read()
    local ok, commands = pcall(vim.json.decode, content)
    if not ok then
        vim.notify('The script is corrupt. Loading default commands', vim.log.levels.WARN)
        return default_commands
    end

    return commands
end

local function save_commands(commands)
    local path = Path:new(commands_file)
    local content = vim.json.encode(commands)
    path:write(content, 'w')
end

local available_commands = load_commands()

local function start_command(command)
    local job = Job:new({
        command = 'sh',
        args = { '-c', command.cmd },
        on_exit = function(j, code)
            local cmd_info = running_commands[command.cmd]
            running_commands[command.cmd] = nil
            if cmd_info then
                vim.schedule(function()
                    vim.notify(string.format('Command finished: %s (exit: %d)', cmd_info.name, code or 0))
                end)
            end
        end,
    })

    job:start()
    running_commands[command.cmd] = {
        job = job,
        name = command.name,
        cmd = command.cmd
    }
    vim.notify(string.format('Started: %s', command.name))
end

local function stop_command(command)
    if running_commands[command.cmd] then
        running_commands[command.cmd].job:shutdown()
        running_commands[command.cmd] = nil
        vim.notify(string.format('Stopped: %s', command.name))
    end
end

function M.execute_custom()
    vim.ui.input({ prompt = 'Enter command: ' }, function(cmd)
        if cmd then
            start_command({ name = 'Custom: ' .. cmd, cmd = cmd })
        end
    end)
end

function M.add_command()
    local function add_to_commands(name, cmd)
        if name and cmd then
            table.insert(available_commands, { name = name, cmd = cmd })
            save_commands(available_commands)
            vim.notify(string.format('Command added: %s', name), vim.log.levels.INFO)
        end
    end

    vim.ui.input({ prompt = 'Command Name: ' }, function(name)
        if name then
            vim.ui.input({ prompt = 'Command: ' }, function(cmd)
                add_to_commands(name, cmd)
            end)
        end
    end)
end

function M.remove_command()
    local opts = {
        prompt_title = 'remove Selected Command',
        finder = require('telescope.finders').new_table({
            results = available_commands,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.name,
                    ordinal = entry.name,
                }
            end,
        }),
        sorter = require('telescope.config').values.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                for i, cmd in ipairs(available_commands) do
                    if cmd.name == selection.value.name then
                        table.remove(available_commands, i)
                        save_commands(available_commands)
                        vim.notify(string.format('Command removed: %s', cmd.name), vim.log.levels.INFO)
                        break
                    end
                end
                actions.close(prompt_bufnr)
            end)
            return true
        end,
    }
    require('telescope.pickers').new({}, opts):find()
end

function M.list_commands()
    local opts = {
        prompt_title = 'Available Commands',
        finder = require('telescope.finders').new_table({
            results = available_commands,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.name,
                    ordinal = entry.name,
                }
            end,
        }),
        sorter = require('telescope.config').values.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                start_command(selection.value)
            end)

            vim.api.nvim_buf_set_keymap(
                prompt_bufnr,
                'i',
                '<C-e>',
                '<cmd>lua require(\'runner\').execute_custom()<CR>',
                { noremap = true, silent = true }
            )

            return true
        end,
    }
    require('telescope.pickers').new({}, opts):find()
end

function M.list_running()
    local running = {}
    for _, cmd in pairs(running_commands) do
        table.insert(running, { name = cmd.name, cmd = cmd.cmd })
    end

    local opts = {
        prompt_title = 'Running Commands',
        finder = require('telescope.finders').new_table({
            results = running,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.name,
                    ordinal = entry.name,
                }
            end,
        }),
        sorter = require('telescope.config').values.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                stop_command(selection.value)
            end)
            return true
        end,
    }
    require('telescope.pickers').new({}, opts):find()
end

function M.setup()
    vim.api.nvim_create_user_command('RunnerCommands', M.list_commands, {})
    vim.api.nvim_create_user_command('RunnerRunning', M.list_running, {})
    vim.api.nvim_create_user_command('RunnerCustom', M.execute_custom, {})
    vim.api.nvim_create_user_command('RunnerAdd', M.add_command, {})
    vim.api.nvim_create_user_command('RunnerRemove', M.remove_command, {})

    function _G.runner_status()
        local names = {}
        for _, cmd in pairs(running_commands) do
            table.insert(names, cmd.name)
        end
        
        if #names == 0 then
            return ''
        end
        
        return string.format('⚡ %s', table.concat(names, ', '))
    end

    vim.o.statusline = vim.o.statusline .. '%{v:lua.runner_status()}'
end

function M.get_running_count()
    return running_commands
end

return M
