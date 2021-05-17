FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build-env
RUN echo "token"
WORKDIR /opt/blogifier
ENV PATH="$PATH:/root/.dotnet/tools"

# Copy everything else and build
COPY ./ /opt/blogifier
RUN rm -rf /var/lib/apt/lists/* && apt update


RUN head -14 /var/lib/apt/lists/partial/deb.debian.org_debian_dists_buster_InRelease
#RUN ["dotnet","publish","./src/Blogifier/Blogifier.csproj","-o","./outputs" ]

RUN mkdir -p /usr/share/man/man1
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN apt-get update; \
    apt-get install -y apt-transport-https && \
    apt-get update && \
    apt-get install -y aspnetcore-runtime-5.0
#RUN apt-get install -y aspnetcore-runtime-5.0

#RUN apt-get update && apt-get install -y openjdk-11-jdk && dotnet tool install --global dotnet-sonarscanner && dotnet tool install --global coverlet.console --version 1.7.1 


RUN dotnet sonarscanner begin \
    /n:"Org: my_project" /v:"version_id" /k:"BF" /d:sonar.host.url="http://localhost:9000" /d:sonar.login="0074b6e6d156527e3594cf90631f5bcdef010127"
 
COPY ./ /opt/blogifier

RUN dotnet restore -v m

RUN dotnet build --no-restore -c Release --nologo
RUN dotnet publish -c Release -o output src/Blogifier/Blogifier.csproj

RUN coverlet tests/Blogifier.Tests.csproj --target "dotnet" --targetargs "test -c Release --no-build" --format opencover
RUN dotnet sonarscanner end /d:sonar.login="0074b6e6d156527e3594cf90631f5bcdef010127"
    
FROM mcr.microsoft.com/dotnet/aspnet:5.0-alpine as run
COPY --from=build-env /opt/blogifier/output /opt/blogifier/output
WORKDIR /opt/blogifier/output
ENTRYPOINT ["dotnet", "Blogifier.dll"]
EXPOSE 80
