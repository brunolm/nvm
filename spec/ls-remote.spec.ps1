InModuleScope power-nvm {
    Describe "Given ls-remote" {
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

        function Assert-RequestNodeJSON() {
            Assert-MockCalled Invoke-WebRequest `
                -Times 1 `
                -ParameterFilter { $Uri -eq "https://nodejs.org/dist/index.json" }
        }

        Context "when called without args" {
            It "should list all available versions" {
                $actual = nvm ls-remote

                (Compare-Object $actual $responseMock -Property version).Length | Should Be 0

                $props = ($actual | Get-Member -MemberType Properties);

                $props.Name.Contains("date") | Should Be $true
                $props.Name.Contains("npm") | Should Be $true
                $props.Name.Contains("version") | Should Be $true

                Assert-RequestNodeJSON
            }
        }

        Context "when called with Filter=8" {
            It "should list all available versions containing 8" {
                $actual = nvm ls-remote 8

                $mock = $responseMock | Where-Object { $_.version.Contains("8") }
                (Compare-Object $actual $mock -Property version).Length | Should Be 0

                Assert-RequestNodeJSON
            }
        }

        Context "when called with Filter=v8" {
            It "should list all available versions containing v8" {
                $actual = nvm ls-remote v8

                $mock = $responseMock | Where-Object { $_.version.Contains("v8") }
                (Compare-Object $actual $mock -Property version).Length | Should Be 0

                Assert-RequestNodeJSON
            }
        }

        Context "when called with Filter=v8.4" {
            It "should list all available versions containing v8.4" {
                $actual = nvm ls-remote v8.4

                $mock = $responseMock | Where-Object { $_.version.Contains("v8.4") }
                (Compare-Object $actual $mock -Property version).Length | Should Be 0

                Assert-RequestNodeJSON
            }
        }

        Context "when called with Filter=v8.4.0" {
            It "should list all available versions containing v8.4.0" {
                $actual = nvm ls-remote v8.4.0

                $mock = $responseMock | Where-Object { $_.version.Contains("v8.4.0") }
                (Compare-Object $actual $mock -Property version).Length | Should Be 0

                Assert-RequestNodeJSON
            }
        }

        Context "when called with Filter=7" {
            It "should list all available versions containing 7" {
                $actual = nvm ls-remote 7

                $mock = $responseMock | Where-Object { $_.version.Contains("7") }
                (Compare-Object $actual $mock -Property version).Length | Should Be 0

                Assert-RequestNodeJSON
            }
        }
    }
}
