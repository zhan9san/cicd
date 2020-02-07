# escape=`

ARG REPO=mcr.microsoft.com/dotnet/framework/runtime
FROM $REPO:4.7-windowsservercore-ltsc2016

# Install VS components
RUN `
    # Install VS Build Tools
    powershell -Command `
        $ProgressPreference = 'SilentlyContinue'; `
        Invoke-WebRequest `
            -UseBasicParsing `
            -Uri https://download.visualstudio.microsoft.com/download/pr/b6a68d31-1a7b-4e99-ae53-de4179e2e529/7945e37dfdf0a711921e807322cfa2e777f11a6183ec173a72ab3ce1e99e53fb/vs_BuildTools.exe `
            -OutFile vs_BuildTools.exe `
    # Installer won't detect DOTNET_SKIP_FIRST_TIME_EXPERIENCE if ENV is used, must use setx /M
    && setx /M DOTNET_SKIP_FIRST_TIME_EXPERIENCE 1 `
    && start /w vs_BuildTools.exe ^ `
        --add Microsoft.VisualStudio.Workload.MSBuildTools ^ `
        --add Microsoft.VisualStudio.Workload.WebBuildTools;includeRecommended ^ `
        --add Microsoft.Net.Component.4.7.SDK ^ `
        --add Microsoft.Net.Component.4.7.TargetingPack ^ `
        --add Microsoft.VisualStudio.Workload.DataBuildTools;includeRecommended ^ `
        --add Microsoft.VisualStudio.Workload.NetCoreBuildTools ^ `
        --add Microsoft.VisualStudio.Workload.NodeBuildTools ^ `
        --add Microsoft.VisualStudio.Workload.OfficeBuildTools ^ `
        --quiet --norestart --nocache --wait `
    && powershell -Command "if ($err = dir $Env:TEMP -Filter dd_setup_*_errors.log | where Length -gt 0 | Get-Content) { throw $err }" `
    && del vs_BuildTools.exe `
    && SET "PATH=%PATH%;%ProgramFiles(x86)%\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\;%ProgramFiles(x86)%\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.7 Tools\;%ProgramFiles(x86)%\Microsoft SDKs\ClickOnce\SignTool\" `
    `
    # Cleanup
    && rmdir /S /Q "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer" `
    && powershell Remove-Item -Force -Recurse "%TEMP%\*" `
    && rmdir /S /Q "%ProgramData%\Package Cache"

# Install other tools
RUN powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" `
    && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin\" `
    && choco install -y git `
    && choco install -y nuget.commandline `
    && choco install -y nodejs --version 8.15.0
