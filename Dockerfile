FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
RUN echo "token"
WORKDIR /opt/blogifier
ENV PATH="$PATH:/root/.dotnet/tools"

#avoid openjdk error
RUN mkdir -p /usr/share/man/man1
#install openjdk11 & sonarscanner & coverlet
RUN apt-get update && apt-get install -y openjdk-11-jdk && dotnet tool install --global dotnet-sonarscanner && dotnet tool install --global coverlet.console --version 3.0.3

#start sonarscanner
RUN dotnet sonarscanner begin \
    /n:"Org: blogifier" /v:"version_id" /k:"BF" /d:sonar.host.url="http://localhost:9000" /d:sonar.login="0074b6e6d156527e3594cf90631f5bcdef010127"

#copy and restore
COPY ./ /opt/blogifier
RUN dotnet restore -v m

COPY . ./
RUN dotnet build --no-restore -c Release --nologo
RUN dotnet publish -c Release -o output src/Blogifier/Blogifier.csproj

RUN coverlet tests/* --target "dotnet" --targetargs "test -c Release --no-build" --format opencover

RUN dotnet sonarscanner end /d:sonar.login="0074b6e6d156527e3594cf90631f5bcdef010127"
    
FROM mcr.microsoft.com/dotnet/aspnet:5.0
WORKDIR /opt/blogifier/output
COPY --from=build /opt/blogifier/output ./
ENTRYPOINT ["dotnet", "Blogifier.dll"]
EXPOSE 80
