using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Microsoft.Extensions.Configuration;

namespace MovieMatch
{
    public class RestEndpoint
    {
        // TODO: Move to base class
        private readonly IConfiguration _configuration;
        public RestEndpoint(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [FunctionName("RestEndpoint")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            // TODO: Load configuration elsewhere and inject
            var keyVaultUri = Environment.GetEnvironmentVariable("KeyVaultUri");
            
            var secretClient = new SecretClient(new Uri(keyVaultUri), new DefaultAzureCredential());
            var secretResponse = await secretClient.GetSecretAsync("movie-db-access-token");            

            string movieDbAccessToken = secretResponse.Value.Value;            

            // TODO: Web call will go here
            var responseMessage = await Task.Run(() =>
            {
                if (movieDbAccessToken.StartsWith("eyJhbGciOiJIUzI1NiJ9."))
                {
                    return "Retrieved access token";
                }                
                else 
                {
                    return "Was not able to retrieve access token";
                }                
            });

            return new OkObjectResult(responseMessage);
        }
    }
}