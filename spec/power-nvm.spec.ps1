Import-Module -Force .\src\power-nvm.psm1

InModuleScope power-nvm {
    Describe "Given ls" {
        Mock Get-ChildItem {
            return @(
                @{Name = "v8.4.1"},
                @{Name = "v8.4.0"},
                @{Name = "v8.3.0"},
                @{Name = "v0.8.0"},
                @{Name = "v7.10.0"}
            );
        }

        Context "when called without args" {
            It "should list all installed folders" {
                $actual = nvm ls;

                $actual.Version -contains "v8.4.1" | Should Be $true
                $actual.Version -contains "v8.4.0" | Should Be $true
                $actual.Version -contains "v8.3.0" | Should Be $true
                $actual.Version -contains "v0.8.0" | Should Be $true
                $actual.Version -contains "v7.10.0" | Should Be $true

                Assert-MockCalled Get-ChildItem -Times 1
            }
        }

        Context "when called with Filter=v8" {
            It "should list installed folders matching v8" {
                $actual = nvm ls "v8";

                $actual.Version -contains "v8.4.1" | Should Be $true
                $actual.Version -contains "v8.4.0" | Should Be $true
                $actual.Version -contains "v8.3.0" | Should Be $true
                $actual.Version -contains "v0.8.0" | Should Be $false
                $actual.Version -contains "v7.10.0" | Should Be $false

                Assert-MockCalled Get-ChildItem -Times 1
            }
        }

        Context "when called with Filter=8" {
            It "should list installed folders matching 8" {
                $actual = nvm ls "8";

                $actual.Version -contains "v8.4.1" | Should Be $true
                $actual.Version -contains "v8.4.0" | Should Be $true
                $actual.Version -contains "v8.3.0" | Should Be $true
                $actual.Version -contains "v0.8.0" | Should Be $false
                $actual.Version -contains "v7.10.0" | Should Be $false

                Assert-MockCalled Get-ChildItem -Times 1
            }
        }

        Context "when called with Filter=8.4" {
            It "should list installed folders matching 8.4" {
                $actual = nvm ls "8.4";

                $actual.Version -contains "v8.4.1" | Should Be $true
                $actual.Version -contains "v8.4.0" | Should Be $true
                $actual.Version -contains "v8.3.0" | Should Be $false
                $actual.Version -contains "v0.8.0" | Should Be $false
                $actual.Version -contains "v7.10.0" | Should Be $false

                Assert-MockCalled Get-ChildItem -Times 1
            }
        }

        Context "when called with Filter=8.4.0" {
            It "should list installed folders matching 8.4.0" {
                $actual = nvm ls "8.4.0";

                $actual.Version -contains "v8.4.1" | Should Be $false
                $actual.Version -contains "v8.4.0" | Should Be $true
                $actual.Version -contains "v8.3.0" | Should Be $false
                $actual.Version -contains "v0.8.0" | Should Be $false
                $actual.Version -contains "v7.10.0" | Should Be $false

                Assert-MockCalled Get-ChildItem -Times 1
            }
        }
    }
}

Start-Sleep 5
