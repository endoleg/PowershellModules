function Get-RegKey
{

	<#
	.SYNOPSIS
	       Gets the registry keys on local or remote computers.

	.DESCRIPTION
	       Use Get-RegKey to get registry keys on local or remote computers
	       
	.PARAMETER ComputerName
	    	An array of computer names. The default is the local computer.

	.PARAMETER Hive
	   	The HKEY to open, from the RegistryHive enumeration. The default is 'LocalMachine'.
	   	Possible values:
	   	
		- ClassesRoot
		- CurrentUser
		- LocalMachine
		- Users
		- PerformanceData
		- CurrentConfig
		- DynData	   	

	.PARAMETER Key
	       The path of the registry key to open.  

	.PARAMETER Name
	       The name of the registry key, Wildcards are permitted.
		
	.PARAMETER Recurse
	   	Gets the registry values of the specified registry key and its sub keys.

	.PARAMETER Ping
	       Use ping to test if the machine is available before connecting to it. 
	       If the machine is not responding to the test a warning message is output.
      		
	.EXAMPLE	   
		Get-RegKey -Key SOFTWARE\Microsoft\PowerShell\1 -Name p* 

		ComputerName Hive         Key                                                      SubKeyCount ValueCount
		------------ ----         ---                                                      ----------- ----------
		COMPUTER1    LocalMachine SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine         0           6
		COMPUTER1    LocalMachine SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns        5           0
		COMPUTER1    LocalMachine SOFTWARE\Microsoft\PowerShell\1\PSConfigurationProviders 1           0

	   	
	   	Description
	   	-----------
	   	Gets all keys from the PowerShell subkey on the local computer with names starts with the letter 'p'.

	.EXAMPLE
		Get-RegKey -Key SOFTWARE\Microsoft\PowerShell\1 -Name p* -Recurse

		ComputerName Hive         Key                                                            SubKeyCount ValueCount
		------------ ----         ---                                                            ----------- ----------
		COMPUTER1    LocalMachine SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine               0           6
		COMPUTER1    LocalMachine SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns              5           0
		COMPUTER1    LocalMachine SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns\PowerGUI_Pro 0           7
		COMPUTER1    LocalMachine SOFTWARE\Microsoft\PowerShell\1\PSConfigurationProviders       1           0

	   	Description
	   	-----------
	   	Gets all keys and subkeys from the PowerShell subkey on the local computer with names starts with the letter 'p'.

	.EXAMPLE
		Get-RegKey -ComputerName SERVER1 -Key SOFTWARE\Microsoft\PowerShell\1 -Name p* | Get-RegValue

		ComputerName Hive            Key                  Value                     Data                 Type
		------------ ----            ---                  -----                     ----                 ----
		SERVER1      LocalMachine    SOFTWARE\Microsof... ApplicationBase           C:\Windows\System... String
		SERVER1      LocalMachine    SOFTWARE\Microsof... PSCompatibleVersion       1.0, 2.0             String
		SERVER1      LocalMachine    SOFTWARE\Microsof... RuntimeVersion            v2.0.50727           String
		SERVER1      LocalMachine    SOFTWARE\Microsof... ConsoleHostAssemblyName   Microsoft.PowerSh... String
		SERVER1      LocalMachine    SOFTWARE\Microsof... ConsoleHostModuleName     C:\Windows\System... String
		SERVER1      LocalMachine    SOFTWARE\Microsof... PowerShellVersion         2.0                  String

	   	Description
	   	-----------
	   	Gets all keys and subkeys from the PowerShell subkey on the remote server SERVER1 with names starts with the letter 'p'.
	   	Pipe the results to Get-RegValue to get all value types under these keys.

	.OUTPUTS
		PSFanatic.Registry.RegistryKey (PSCustomObject)

	.NOTES
		Author: Shay Levy
		Blog  : http://blogs.microsoft.co.il/blogs/ScriptFanatic/
		
	.LINK
		http://code.msdn.microsoft.com/PSRemoteRegistry

	.LINK
		New-RegKey
		Remove-RegKey
		Test-RegKey

	#>
		

	[OutputType('PSFanatic.Registry.RegistryKey')]
	[CmdletBinding(DefaultParameterSetName="__AllParameterSets")]
	
	param( 
		[Parameter(
			Position=0,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true
		)]		
		[Alias("CN","__SERVER","IPAddress")]
		[string[]]$ComputerName="",		

		[Parameter(
			Position=1,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="The HKEY to open, from the RegistryHive enumeration. The default is 'LocalMachine'."
		)]
		[ValidateSet("ClassesRoot","CurrentUser","LocalMachine","Users","PerformanceData","CurrentConfig","DynData")]
		[string]$Hive="LocalMachine",

		[Parameter(
			Mandatory=$true,
			Position=2,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="The path of the subkey to open."
		)]
		[string]$Key,
		
		[Parameter(
			Mandatory=$false,
			Position=3,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="The name of the value to set."
		)]	
		[string]$Name="*",		
	
		[switch]$Ping,
		
		[switch]$Recurse
	) 

	begin
	{
		Write-Verbose "Enter begin block..."
	
		function Recurse($Key){
		
			Write-Verbose "Start recursing, key is [$Key]"

			try
			{
			
				$subKey = $reg.OpenSubKey($key)
				
				if(!$subKey)
				{
					Throw "Key '$Key' doesn't exist."
				}
				
			
				foreach ($k in $subKey.GetSubKeyNames())
				{							
					if($k -like $Name)
					{
						$child = $subKey.OpenSubKey($k)
						$pso = New-Object PSObject -Property @{
							ComputerName=$c
							Hive=$Hive
							Key="$Key\$k"								
							ValueCount=$child.ValueCount
							SubKeyCount=$child.SubKeyCount
						}

						Write-Verbose "Recurse: Adding format type name to custom object."
						$pso.PSTypeNames.Clear()
						$pso.PSTypeNames.Add('PSFanatic.Registry.RegistryKey')
						$pso
					}
						
					Recurse "$Key\$k"		
				}
				
			}
			catch
			{
				Write-Error $_
			}
			
			Write-Verbose "Ending recurse, key is [$Key]"
		}
		
		Write-Verbose "Exit begin block..."
	}
	

	process
	{


	    	Write-Verbose "Enter process block..."
		
		foreach($c in $ComputerName)
		{	
			try
			{				
				if($c -eq "")
				{
					$c=$env:COMPUTERNAME
					Write-Verbose "Parameter [ComputerName] is not presnet, setting its value to local computer name: [$c]."
					
				}
				
				if($Ping)
				{
					Write-Verbose "Parameter [Ping] is presnet, initiating Ping test"
					
					if( !(Test-Connection -ComputerName $c -Count 1 -Quiet))
					{
						Write-Warning "[$c] doesn't respond to ping."
						return
					}
				}
				
				
				Write-Verbose "Starting remote registry connection against: [$c]."
				Write-Verbose "Registry Hive is: [$Hive]."
				$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]$Hive,$c)		
	
								
				if($Recurse)
				{
					Write-Verbose "Parameter [Recurse] is presnet, calling Recurse function."
					Recurse $Key
				}
				else
				{					
				
					Write-Verbose "Open remote subkey: [$Key]."			
					$subKey = $reg.OpenSubKey($Key)
					
					if(!$subKey)
					{
						Throw "Key '$Key' doesn't exist."
					}
					
					Write-Verbose "Start get remote subkey: [$Key] keys."
					foreach ($k in $subKey.GetSubKeyNames())
					{
						if($k -like $Name)
						{						
							$child = $subKey.OpenSubKey($k)
							$pso = New-Object PSObject -Property @{
								ComputerName=$c
								Hive=$Hive
								Key="$Key\$k"								
								ValueCount=$child.ValueCount
								SubKeyCount=$child.SubKeyCount
							}

							Write-Verbose "Recurse: Adding format type name to custom object."
							$pso.PSTypeNames.Clear()
							$pso.PSTypeNames.Add('PSFanatic.Registry.RegistryKey')
							$pso
						}
					}				
				}
				
				Write-Verbose "Closing remote registry connection on: [$c]."
				$reg.close()
			}
			catch
			{
				Write-Error $_
			}
		} 
	
		Write-Verbose "Exit process block..."
	}
}