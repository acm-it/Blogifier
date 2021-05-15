FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build-env

WORKDIR /opt/blogifier
ENV PATH="$PATH:/root/.dotnet/tools"

# Copy everything else and build
COPY ./ /opt/blogifier


#RUN ["dotnet","publish","./src/Blogifier/Blogifier.csproj","-o","./outputs" ]

RUN mkdir -p /usr/share/man/man1
RUN apt-get update && apt-get install -y openjdk-11-jdk && dotnet tool install --global dotnet-sonarscanner && dotnet tool install --global coverlet.console --version 1.7.1

RUN dotnet sonarscanner begin \
    /n:"Org: my_project" /v:"version_id" /k:"BF" /d:sonar.host.url="http://localhost:9000" /d:sonar.login="0074b6e6d156527e3594cf90631f5bcdef010127"
 
COPY ./ /opt/blogifier

RUN dotnet restore -v m

RUN dotnet build --no-restore -c Release --nologo
RUN dotnet publish -c Release -o out src/Blogifier/Blogifier.csproj

RUN coverlet tests/Blogifier.Tests.csproj --target "dotnet" --targetargs "test -c Release --no-build" --format opencover
RUN dotnet sonarscanner end /d:sonar.login="token"
    
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1
COPY --from=build-env /opt/blogifier/outputs .
WORKDIR /opt/blogifier
ENTRYPOINT ["dotnet", "Blogifier.dll"]
EXPOSE 80
