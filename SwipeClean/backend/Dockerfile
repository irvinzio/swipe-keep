FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ./src ./src
COPY SwipeClean.sln ./
RUN dotnet restore src/SwipeClean.API/SwipeClean.API.csproj
RUN dotnet publish src/SwipeClean.API/SwipeClean.API.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "SwipeClean.API.dll"]
