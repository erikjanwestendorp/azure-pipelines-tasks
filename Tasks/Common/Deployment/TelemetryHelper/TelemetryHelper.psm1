# Telemetry Codes
$telemetryCodes =
@{
    "Input_Validation"   = "Input_Validation_Error";
    "Task_InternalError" = "Task_Internal_Error";
    "DTLSDK_Error"       = "Dtl_Sdk_Error";
}

# Telemetry Write Method
function Write-Telemetry
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$codeKey,

        [Parameter(Position = 2)]
        [string]$errorMsg
    )

    $erroCodeMsg = $telemetryCodes[$codeKey]

    ## If no error is passed mark it as not available
    if ([string]::IsNullOrEmpty($errorMsg))
    {
        $errorMsg = "No error details available"
    }

    $errorCode = @{
        $erroCodeMsg = $errorMsg
    }

    ## Form errorcode as json string
    $erroCode = ConvertTo-Json -InputObject $errorCode -Compress
    $telemetryString = "##vso[task.logissue type=error;code=" + $erroCode + ";]"
    Write-Host $telemetryString
}

function Get-ExceptionData
{
    param(
        [System.Management.Automation.ErrorRecord]
        $error
    )

    $exceptionData = ""
    try
    {
        $src = $error.InvocationInfo.PSCommandPath + "|" + $error.InvocationInfo.ScriptLineNumber
        $exceptionTypes = ""

        $exception = $error.Exception
        if ($exception.GetType().Name -eq 'AggregateException')
        {
            $flattenedException = ([System.AggregateException]$exception).Flatten()
            $flattenedException.InnerExceptions | ForEach-Object {
                $exceptionTypes += $_.GetType().FullName + ";"
            }
        }
        else
        {
            do
            {
                $exceptionTypes += $exception.GetType().FullName + ";"
                $exception = $exception.InnerException
            } while ($exception -ne $null)
        }
        $exceptionData = "$exceptionTypes|$src"
    }
    catch
    {}

    return $exceptionData
}

# Export only the public function.
Export-ModuleMember -Function Write-Telemetry
Export-ModuleMember -Function Get-ExceptionData
Export-ModuleMember -Variable telemetryCodes