using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.Owin;
using Microsoft.Owin;
using Microsoft.Owin.Security.Cookies;
using Microsoft.Owin.Security.Google;
using Owin;
using ContosoClinic.Models;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Azure.KeyVault;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data;
using System.Data.SqlClient;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Microsoft.SqlServer.Management.AlwaysEncrypted.AzureKeyVaultProvider;

namespace ContosoClinic
{
    public partial class Startup
    {
        public async static Task<string> GetToken(string authority, string resource, string scope)
        {
            var authContext = new AuthenticationContext(authority);
            AzureServiceTokenProvider azureServiceTokenProvider = new AzureServiceTokenProvider();
            string accessToken = azureServiceTokenProvider.GetAccessTokenAsync("https://tamz-demovault.vault.azure.net/").Result;
            AuthenticationResult result = await authContext.AcquireTokenAsync(resource, _clientCredential);
            if (result == null) throw new InvalidOperationException("Failed to obtain the access token"); return result.AccessToken;
        }

        static void InitializeAzureKeyVaultProvider()
        {

            SqlColumnEncryptionAzureKeyVaultProvider azureKeyVaultProvider =
               new SqlColumnEncryptionAzureKeyVaultProvider(accessToken);

            Dictionary<string, SqlColumnEncryptionKeyStoreProvider> providers =
               new Dictionary<string, SqlColumnEncryptionKeyStoreProvider>();

            providers.Add(SqlColumnEncryptionAzureKeyVaultProvider.ProviderName, azureKeyVaultProvider);
            SqlConnection.RegisterColumnEncryptionKeyStoreProviders(providers);
        }

    }

}