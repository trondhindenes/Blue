FROM microsoft/powershell:latest
ADD . Blue
#RUN Set-Variable VerbosePreference Continue
#RUN ipmo ./Blue/blue.psd1