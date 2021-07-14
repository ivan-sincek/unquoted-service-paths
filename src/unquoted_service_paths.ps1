$services = $null;
$info = $null;
try {
	Write-Host "Fetching the list of services, this may take a while...";
	$services = Get-WmiObject -Class Win32_Service | Where-Object { $_.PathName -inotmatch "`"" -and $_.PathName -inotmatch ":\\Windows\\" -and ($_.StartMode -eq "Auto" -or $_.StartMode -eq "Manual") -and ($_.State -eq "Running" -or $_.State -eq "Stopped") };
	if ($($services | Measure).Count -lt 1) {
		Write-Host "";
		Write-Host "No unquoted service paths were found";
	} else {
		$services | Sort-Object -Property ProcessId, Name | Format-List -Property ProcessId, Name, DisplayName, PathName, StartName, StartMode, State;
		$name = $(Read-Host -Prompt "Enter service name").Trim();
		Write-Host "";
		if ($name.Length -lt 1) {
			Write-Host "Service name is rquired";
		} else {
			$exists = $false;
			foreach ($service in $services) {
				if ($service.Name -eq $name) {
					$exists = $true;
					break;
				}
			}
			if ($exists) {
				Write-Host "[1] Start   ";
				Write-Host "[2] Stop    ";
				Write-Host "[3] Restart ";
				Write-Host "------------";
				$choice = $(Read-Host -Prompt "Your choice").Trim();
				Write-Host "";
				if ($choice -eq "1" -or $choice -eq "2" -or $choice -eq "3") {
					$info = Get-Service -Name $service.Name;
					if ($choice -eq "2" -or $choice -eq "3") {
						if ($info.Status -eq "Stopped") {
							Write-Host "Service is not running";
						} elseif ($service.StopService().ReturnValue -ne 0) {
							Write-Host "Cannot stop the service";
						} else {
							do {
								Start-Sleep -Milliseconds 200;
								$info.Refresh();
							} while ($info.Status -ne "Stopped");
							Write-Host "Service has been stopped successfully";
						}
					}
					if ($choice -eq "3") {
						Write-Host "";
					}
					if ($choice -eq "1" -or $choice -eq "3") {
						if ($info.Status -eq "Running") {
							Write-Host "Service is already running";
						} elseif ($service.StartService().ReturnValue -ne 0) {
							Write-Host "Cannot start the service";
						} else {
							do {
								Start-Sleep -Milliseconds 200;
								$info.Refresh();
							} while ($info.Status -ne "Running");
							Write-Host "Service has been started successfully";
						}
					}
				} else {
					Write-Host "Invalid choice";
				}
			} else {
				Write-Host "Service does not exists";
			}
		}
	}
} catch {
	Write-Host $_.Exception.InnerException.Message;
} finally {
	if ($services -ne $null) {
		$services.Dispose();
	}
	if ($info -ne $null) {
		$info.Close();
		$info.Dispose();
	}
}
