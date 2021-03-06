
###################################################################
#    Copyright (c) Microsoft. All rights reserved.
#    This code is licensed under the Microsoft Public License.
#    THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
#    ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
#    IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
#    PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
###################################################################

##################################################
# Test-GetInstance
##################################################

begin {
    # import modules
    Import-Module .\OrchestratorServiceModule.psm1
}

process {
    # get credentials (set to $null to UseDefaultCredentials)
    $creds = $null
    #$creds = Get-Credential "DOMAIN\USERNAME"

    # create the base url to the service
    $url = Get-OrchestratorServiceUrl -server "SERVERNAME"

    # Define JobId
    $jobid = [guid]"GUID"

    $job = Get-OrchestratorJob -serviceurl $url -jobid $jobid -credentials $creds
    Write-Host "job.Id = " $job.Id

    $instances = Get-OrchestratorRunbookInstance -job $job -credentials $creds
    
    $i = 1
    foreach ($instance in $instances)
    {
        Write-Host " "
        Write-Host "INSTANCE " $i
        Write-Host "Url = " $instance.Url
        Write-Host "Url_Service = " $instance.Url_Service
        Write-Host "Url_Runbook = " $instance.Url_Runbook
        Write-Host "Url_Job = " $instance.Url_Job
        Write-Host "Url_Parameters = " $instance.Url_Parameters
        Write-Host "Url_ActivityInstances = " $instance.Url_ActivityInstances
        Write-Host "Url_RunbookServer = " $instance.Url_RunbookServer
        Write-Host "Published = " $instance.Published
        Write-Host "Updated = " $instance.Updated
        Write-Host "Category = " $instance.Category
        Write-Host "Id =  " $instance.Id
        Write-Host "RunbookId = " $instance.RunbookId
        Write-Host "JobId = " $instance.JobId
        Write-Host "RunbookServerId = " $instance.RunbookServerId
        Write-Host "Status = " $instance.Status
        Write-Host "CreationTime = " $instance.CreationTime
        Write-Host "CompletionTime = " $instance.CompletionTime
        $i++
    }    
}

end {
    # remove modules
    Remove-Module OrchestratorServiceModule
}
