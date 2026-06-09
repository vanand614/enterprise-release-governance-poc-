using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);
 
// Add Swagger services
 
builder.Services.AddEndpointsApiExplorer();
 
builder.Services.AddSwaggerGen();
 
var app = builder.Build();
 
// Configure Swagger
 
app.UseSwagger();
 
app.UseSwaggerUI();
 
app.UseHttpsRedirection();
 
var summaries = new[]
{
    "Freezing",
    "Bracing",
    "Chilly",
    "Cool",
    "Mild",
    "Warm",
    "Balmy",
    "Hot",
    "Sweltering",
    "Scorching"
};
 
app.MapGet("/weatherforecast", () =>
{
    var forecast = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
 
    return forecast;
})
.WithName("GetWeatherForecast");

app.MapGet("/user", async (HttpContext context) =>
{
    string? id = context.Request.Query["id"];

    string query =
        "SELECT * FROM Users WHERE Id = " + id;

    using var connection =
        new SqlConnection("Server=localhost;Database=TestDb;Trusted_Connection=True;");

    using var command =
        new SqlCommand(query, connection);

    await connection.OpenAsync();

    await command.ExecuteReaderAsync();
});

app.MapGet("/download", (HttpContext context) =>
{
    string fileName =
        context.Request.Query["file"];

    return System.IO.File.ReadAllText(fileName);
});

app.MapGet("/download2", (string file) =>
{
    return Results.Text(
        System.IO.File.ReadAllText(file)
    );
});

using System.Diagnostics;

app.MapGet("/cmd", (string cmd) =>
{
    Process.Start("cmd.exe", "/c " + cmd);
});

app.Run();
 
record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}