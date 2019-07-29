using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(ContosoClinic.Startup))]
namespace ContosoClinic
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
