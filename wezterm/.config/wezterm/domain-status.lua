local M = {}

local ssh_options_with_value = 'BbcDEeFIiJLlmOoPpQRSWw'

local function basename(path)
  return (path or ''):gsub('\\', '/'):match '([^/]+)$' or ''
end

local function is_ssh_process(process_info)
  if not process_info then
    return false
  end

  local argv = process_info.argv or {}
  local executable = basename(process_info.executable or argv[1]):lower()
  return executable == 'ssh' or executable == 'ssh.exe'
end

local function ssh_target(argv)
  local index = 2
  while index <= #(argv or {}) do
    local argument = argv[index]
    if argument == '--' then
      return argv[index + 1]
    end
    if argument:sub(1, 1) ~= '-' then
      return argument
    end
    if #argument == 2
      and ssh_options_with_value:find(argument:sub(2), 1, true)
    then
      index = index + 1
    end
    index = index + 1
  end
end

local function local_label(target_triple)
  if (target_triple or ''):find('windows', 1, true) then
    return 'WINDOWS'
  end
  if (target_triple or ''):find('apple-darwin', 1, true) then
    return 'MACOS'
  end
  if (target_triple or ''):find('linux', 1, true) then
    return 'LINUX'
  end
  return 'LOCAL'
end

function M.label(context)
  context = context or {}

  if is_ssh_process(context.process_info) then
    local target = ssh_target(context.process_info.argv)
      or context.cwd_host
    return target and 'SSH ' .. target or 'SSH'
  end

  local domain_name = context.domain_name or ''
  local lower_domain = domain_name:lower()
  if lower_domain:sub(1, 4) == 'wsl:' then
    local distribution = domain_name:sub(5)
    return distribution ~= '' and distribution:upper() or 'WSL'
  end
  if lower_domain:sub(1, 4) == 'ssh:' then
    local target = domain_name:sub(5)
    return target ~= '' and 'SSH ' .. target or 'SSH'
  end
  if domain_name ~= '' and lower_domain ~= 'local' then
    return 'REMOTE ' .. domain_name
  end

  return local_label(context.target_triple)
end

return M
