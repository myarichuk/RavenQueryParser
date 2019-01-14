using System.IO;
using System.Text;

namespace RavenQuery.SyntaxTester
{
    public static class ManifestResource
    {
        public static string Load(string resourceName)
        {
            var assembly = typeof(MainWindow).Assembly;
            using (var resourceStream = assembly.GetManifestResourceStream(resourceName))
            using (var streamReader = new StreamReader(resourceStream, Encoding.UTF8))
            {
                return streamReader.ReadToEnd();
            }
        }
    }
}
