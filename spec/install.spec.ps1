InModuleScope power-nvm {
    Describe "Given install" {
        $json = '[
            {"version":"v8.4.0","date":"2017-08-15","files":["aix-ppc64","headers","linux-arm64","linux-armv6l","linux-armv7l","linux-ppc64le","linux-x64","linux-x86","osx-x64-pkg","osx-x64-tar","src","sunos-x64","sunos-x86","win-x64-exe","win-x64-msi","win-x86-exe","win-x86-msi"],"npm":"5.3.0","v8":"6.0.286.52","uv":"1.13.1","zlib":"1.2.11","openssl":"1.0.2l","modules":"57","lts":false},
            {"version":"v8.3.0","date":"2017-08-08","files":["aix-ppc64","headers","linux-arm64","linux-armv6l","linux-armv7l","linux-ppc64le","linux-x64","linux-x86","osx-x64-pkg","osx-x64-tar","src","sunos-x64","sunos-x86","win-x64-exe","win-x64-msi","win-x86-exe","win-x86-msi"],"npm":"5.3.0","v8":"6.0.286.52","uv":"1.13.1","zlib":"1.2.11","openssl":"1.0.2l","modules":"57","lts":false},
            {"version":"v8.2.1","date":"2017-07-20","files":["aix-ppc64","headers","linux-arm64","linux-armv6l","linux-armv7l","linux-ppc64le","linux-x64","linux-x86","osx-x64-pkg","osx-x64-tar","src","sunos-x64","sunos-x86","win-x64-exe","win-x64-msi","win-x86-exe","win-x86-msi"],"npm":"5.3.0","v8":"5.8.283.41","uv":"1.13.1","zlib":"1.2.11","openssl":"1.0.2l","modules":"57","lts":false},
            {"version":"v7.10.0","date":"2017-05-02","files":["aix-ppc64","headers","linux-arm64","linux-armv6l","linux-armv7l","linux-ppc64le","linux-x64","linux-x86","osx-x64-pkg","osx-x64-tar","src","sunos-x64","sunos-x86","win-x64-exe","win-x64-msi","win-x86-exe","win-x86-msi"],"npm":"4.2.0","v8":"5.5.372.43","uv":"1.11.0","zlib":"1.2.11","openssl":"1.0.2k","modules":"51","lts":false},
            {"version":"v0.8.0","date":"2012-06-22","files":["osx-x64-pkg","src","win-x64-exe","win-x86-exe","win-x86-msi"],"npm":"1.1.32","v8":"3.11.10.10","uv":"0.8","zlib":"1.2.3","openssl":"1.0.0f","modules":"1","lts":false}]';

        $responseMock = ($json | ConvertFrom-Json);

        Mock Invoke-WebRequest {
            return $json;
        }

        Mock Get-NodeVersionsDir {
            return "C:\tmp\versions";
        }

        Mock Test-Path { return $true; }

        Mock Get-ChildItem {
            return @(
                @{
                    FullName="C:\tmp\node-v8.4.0";
                    Name="node-v8.4.0";
                    Parent=@{
                        FullName = "C:\tmp";
                    };
                },
                @{Name="node-v8.4.0"}
            );
        }

        Mock 7z
        Mock Expand-Archive
        Mock Remove-Item -Verifiable
        Mock Move-Item -Verifiable

        function Assert-RequestNodeJSON() {
            Assert-MockCalled Invoke-WebRequest `
                -Times 1 `
                -ParameterFilter { $Uri -eq "https://nodejs.org/dist/index.json" }
        }

        Context "when called with Version=latest" {
            It "should install first found version on json" {
                nvm install latest

                Assert-VerifiableMocks
                Assert-RequestNodeJSON
            }
        }
    }
}
