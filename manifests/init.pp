# windows_join_domain
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include windows_join_domain
#
<<<<<<< HEAD
class windows_join_domain (
=======
class windowsjoindomain (
>>>>>>> 9c5f3103feedb9953d6f6be4efcb65a311076288
  String  $domain,
  String  $username,
  String  $password,
  Boolean $secure_password = false,
  Optional[String]  $machine_ou      = undef,
  Boolean $resetpw         = true,
  Boolean $reboot          = true,
  String  $join_options    = '3',
  Optional[String]  $user_domain     = undef,
){

  if $windows_join_domain::secure_password {
    $_password = "(New-Object System.Management.Automation.PSCredential('user',(convertto-securestring '${password}'))).GetNetworkCredential().password"
  }else{
    $_password = "'${password}'"
  }

  if $windows_join_domain::machine_ou {
    validate_string($windows_join_domain::machine_ou)
    $_machine_ou = "'${machine_ou}'"
  }else{
    $_machine_ou = '$null'
  }

  if $windows_join_domain::user_domain {
    $_user_domain = $windows_join_domain::user_domain
    $_reset_username = "${user_domain}\\${username}"
  } else {
    $_user_domain = $windows_join_domain::domain
    $_reset_username = $windows_join_domain::username
  }

  $command = "(Get-WmiObject -Class Win32_ComputerSystem).JoinDomainOrWorkGroup('${domain}',${_password},'${username}@${_user_domain}',${_machine_ou},${join_options})"

  exec { 'join_domain':
    command  => "exit ${command}.ReturnValue",
    unless   => "if((Get-WmiObject -Class Win32_ComputerSystem).domain -ne '${domain}'){ exit 1 }",
    provider => powershell,
  }

  if $windows_join_domain::resetpw {
    exec { 'reset_computer_trust':
      command  => "netdom /RESETPWD /UserD:${_reset_username} /PasswordD:${_password} /Server:${domain}",
      unless   => "if ($(nltest /sc_verify:${domain}) -match 'ERROR_INVALID_PASSWORD') {exit 1}",
      provider => powershell,
      require  => Exec['join_domain'],
    }
  }

  if $windows_join_domain::reboot {
    reboot { 'after':
      subscribe => Exec['join_domain'],
      apply     => finished,
    }
  }
}
