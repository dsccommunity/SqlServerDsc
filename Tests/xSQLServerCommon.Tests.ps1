[CmdletBinding()]
# Suppressing this because we need to generate a mocked credentials that will be passed along to the examples that are needed in the tests.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$script:moduleRoot = Split-Path $PSScriptRoot -Parent

Describe 'xSQLServer module common tests' {
    Context -Name 'When there are example file for resource' {
            <#
                For Appveyor builds copy the module to the system modules directory so it falls
                in to a PSModulePath folder and is picked up correctly.
            #>
            if ($env:APPVEYOR)
            {
                $powershellModulePath = Join-Path -Path (($env:PSModulePath -split ';')[0]) -ChildPath 'xSQLServer'
                Copy-item -Path $env:APPVEYOR_BUILD_FOLDER -Destination $powershellModulePath -Recurse -Force
            }

            $mockPassword = ConvertTo-SecureString '&iPm%M5q3K$Hhq=wcEK' -AsPlainText -Force
            $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('username', $mockPassword)
            $mockConfigData = @{
                AllNodes = @(
                    @{
                        NodeName = "localhost"
                        PSDscAllowPlainTextPassword = $true
                    }
                )
            }

            $exampleFile = Get-ChildItem -Path "$script:moduleRoot\Examples\Resources" -Filter "*.ps1" -Recurse

            foreach ($exampleToValidate in $exampleFile)
            {
                $exampleDescriptiveName = Join-Path -Path (Split-Path $exampleToValidate.Directory -Leaf) -ChildPath (Split-Path $exampleToValidate -Leaf)

                It "Should compile MOFs for example '$exampleDescriptiveName' correctly" {
                    {
                        . $exampleToValidate.FullName

                        $exampleCommand = Get-Command Example -ErrorAction SilentlyContinue
                        if ($exampleCommand)
                        {
                            try
                            {
                                $params = @{}
                                $exampleCommand.Parameters.Keys | Where-Object { $_ -like '*Account' -or ($_ -like '*Credential' -and $_ -ne 'PsDscRunAsCredential')  } | ForEach-Object -Process {
                                    $params.Add($_, $mockCredential)
                                }

                                Example @params -ConfigurationData $mockConfigData -OutputPath 'TestDrive:\' -ErrorAction Continue -WarningAction SilentlyContinue | Out-Null
                            }
                            finally
                            {
                                # Remove the function we dot-sourced so next example file doesn't use the previous Example-function.
                                Remove-Item function:Example
                            }
                        }
                        else
                        {
                            throw "The example '$exampleDescriptiveName' does not contain a function 'Example'."
                        }
                    } | Should Not Throw
                }
        }

        if ($env:APPVEYOR -eq $true)
        {
            Remove-item -Path $powershellModulePath -Recurse -Force -Confirm:$false

            # Restore the module in 'memory' to ensure other tests after this test have access to it
            Import-Module -Name "$script:moduleRoot\xSQLServer.psd1" -Global -Force
        }
    }

    Context -Name 'When there are Markdown files in the module' {
        if (Get-Command npm)
        {
            It 'Should not throw an error when installing dependencies' {
                {
                    <#
                        gulp; gulp is a toolkit that helps you automate painful or time-consuming tasks in your development workflow.
                        gulp must be installed globally to be able to be called through Start-Process
                    #>
                    Start-Process -FilePath "npm" -ArgumentList "install -g gulp" -WorkingDirectory $script:moduleRoot -Wait -WindowStyle Hidden

                    # gulp must also be installed locally to be able to be referenced in the javascript file.
                    Start-Process -FilePath "npm" -ArgumentList "install gulp" -WorkingDirectory $script:moduleRoot -Wait -WindowStyle Hidden

                    # Used in gulpfile.js; A tiny wrapper around Node streams2 Transform to avoid explicit subclassing noise
                    Start-Process -FilePath "npm" -ArgumentList "install through2" -WorkingDirectory $script:moduleRoot -Wait -WindowStyle Hidden

                    # Used in gulpfile.js; A Node.js style checker and lint tool for Markdown/CommonMark files.
                    Start-Process -FilePath "npm" -ArgumentList "install markdownlint" -WorkingDirectory $script:moduleRoot -Wait -WindowStyle Hidden

                    # gulp-concat is installed as devDependencies. Used in gulpfile.js; Concatenates files
                    Start-Process -FilePath "npm" -ArgumentList "install gulp-concat -D" -WorkingDirectory $script:moduleRoot -Wait -WindowStyle Hidden
                } | Should Not Throw
            }

            It 'Should not have an error in any Markdown files' {
                $markdownError = 0

                try
                {
                    # This executes the gulpfile.js in the root folder of the module.
                    Start-Process -FilePath "gulp" -ArgumentList "test-mdsyntax --silent" -WorkingDirectory $script:moduleRoot -Wait -NoNewWindow

                    # Wait 3 seconds so the locks on file 'markdownerror.txt' has been released.
                    Start-Sleep -Seconds 3

                    $markdownFoundErrorPath = Join-Path -Path $script:moduleRoot -ChildPath "markdownerror.txt"

                    if ((Test-Path -Path $markdownFoundErrorPath))
                    {
                        Get-Content -Path $markdownFoundErrorPath | ForEach-Object -Process {
                            if (-not [string]::IsNullOrEmpty($_))
                            {
                                Write-Warning -Message $_

                                $markdownError++
                            }
                        }
                    }

                    <#
                        When running in AppVeyor. Wait 5 seconds so the output have time to be sent to AppVeyor Console.
                        If there are many errors, the AppVeyor Console doesn't have time to print all warning messages
                        and messages comes out of order.
                    #>
                    if( $env:APPVEYOR )
                    {
                        Start-Sleep -Seconds 5
                    }
                }
                catch [System.Exception]
                {
                    Write-Warning -Message "Unable to run gulp to test Markdown files. Please be sure that you have installed node.js. Error: $_"
                }

                # Removes the 'markdownerror.txt' file from the module root so it is not shipped.
                Remove-Item -Path $markdownFoundErrorPath -Force -ErrorAction SilentlyContinue

                # The actual test that will fail the build if it is not zero.
                $markdownError | Should Be 0
            }

            It 'Should not throw an error when uninstalling dependencies' {
                {
                    # Uninstalled npm packages in reverse order
                    Start-Process -FilePath "npm" -ArgumentList "uninstall gulp-concat -D" -WorkingDirectory $script:moduleRoot -Wait -PassThru  -WindowStyle Hidden
                    Start-Process -FilePath "npm" -ArgumentList "uninstall markdownlint" -WorkingDirectory $script:moduleRoot -Wait -PassThru  -WindowStyle Hidden
                    Start-Process -FilePath "npm" -ArgumentList "uninstall through2" -WorkingDirectory $script:moduleRoot -Wait -PassThru  -WindowStyle Hidden
                    Start-Process -FilePath "npm" -ArgumentList "uninstall gulp" -WorkingDirectory $script:moduleRoot -Wait -PassThru  -WindowStyle Hidden
                    Start-Process -FilePath "npm" -ArgumentList "uninstall -g gulp" -WorkingDirectory $script:moduleRoot -Wait -PassThru  -WindowStyle Hidden

                    # Remove folder node_modules that npm created.
                    $npmNpdeModulesPath = (Join-Path -Path $script:moduleRoot -ChildPath 'node_modules')
                    if( Test-Path -Path $npmNpdeModulesPath)
                    {
                        Remove-Item -Path $npmNpdeModulesPath -Recurse -Force
                    }
                } | Should Not Throw
            }
        }
        else
        {
            Write-Warning -Message 'Cannot find npm to install dependencies needed to test markdown files. Skipping this test!'
        }
    }
}
