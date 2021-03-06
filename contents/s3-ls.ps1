#Requires -Version 4

<#
.SYNOPSIS
  List AWS bucket objects
.DESCRIPTION
  List AWS bucket objects
.NOTES
  Version:        1.0.0
  Author:         Rundeck
  Creation Date:  12/12/2017
  
#>

Begin {
  
  if($Env:RD_CONFIG_ACCESS_KEY){
      $env:AWS_ACCESS_KEY_ID=$Env:RD_CONFIG_ACCESS_KEY
  }

  if($Env:RD_CONFIG_SECRET_ACCESS_KEY){
       $env:AWS_SECRET_ACCESS_KEY=$Env:RD_CONFIG_SECRET_ACCESS_KEY
  }

  if($Env:RD_CONFIG_DEFAULT_REGION){
       $env:AWS_DEFAULT_REGION=$Env:RD_CONFIG_DEFAULT_REGION
  }
}


Process {


    try{

        $path = $Env:RD_CONFIG_S3URI
        $retries  = $Env:RD_CONFIG_RETRIES

        if($Env:RD_JOB_LOGLEVEL -ieq "DEBUG"){
            $VerbosePreference="Continue"
            $DebugPreference="Continue"
        }

        if($Env:RD_CONFIG_CHECKEXEC -eq "true"){
            if (Test-Path "$($Env:RD_CONFIG_FILEEXISTS)"){
                write-host "Filechecker: Found $($Env:RD_CONFIG_FILEEXISTS). Continuing execution."
            }else{
                Write-Warning "Filechecker: Did not find $($Env:RD_CONFIG_FILEEXISTS). Skipping execution."
                exit 0
            }
        }

        write-verbose "Path: $($path)"

        $cmd = "aws s3 ls $path "
        
        if($Env:RD_CONFIG_QUIET -eq "true"){
            $cmd += " --quiet "
        }

        if($Env:RD_CONFIG_HUMAN_READABLE -eq "true"){
            $cmd += " --human-readable "
        }

        if($Env:RD_CONFIG_SUMMARIZE -eq "true"){
            $cmd += " --summarize "
        }

        if($Env:RD_CONFIG_PAGE_SIZE -eq "true"){
            $cmd += " --page-size "
        }

        if($Env:RD_CONFIG_ENDPOINT_URL){
            $cmd +=  " --endpoint-url $($Env:RD_CONFIG_ENDPOINT_URL) " 
        }

        if($Env:RD_CONFIG_RECURSIVE -eq "true"){
            $cmd += " --recursive "
        }


        $completed = $false
        $retrycount = 1
        $secondsDelay = 2

        while (-not $completed) {

            Try{
                Invoke-Expression $cmd
                if ($lastexitcode) {throw "Error running command"}

                Write-Verbose ("Command [{0}] succeeded." -f $cmd)
                $completed = $true
            }Catch{
                if ($retrycount -ge $retries) {
                    Write-Host ("Command [{0}] failed the maximum number of {1} times." -f $cmd, $retrycount)
                    throw
                } else {
                    Write-Host ("Command [{0}] failed. Retrying in {1} seconds." -f $cmd, $secondsDelay)
                    Start-Sleep $secondsDelay
                    $retrycount++
                }
            }
        }

    }Catch{
        Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
        exit 1
    }

}

