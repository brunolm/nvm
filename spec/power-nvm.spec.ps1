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

        Context "When called without args" {
            It "should list all installed folders" {
                (nvm ls).Version -contains "v8.4.1" | Should Be $true
                (nvm ls).Version -contains "v8.4.0" | Should Be $true
                (nvm ls).Version -contains "v8.3.0" | Should Be $true
                (nvm ls).Version -contains "v0.8.0" | Should Be $true
                (nvm ls).Version -contains "v7.10.0" | Should Be $true

                Assert-MockCalled Get-ChildItem -Times 1
            }
        }

        Context "When called with Filter=v8" {
            It "should list installed folders matching v8" {
                (nvm ls "v8").Version -contains "v8.4.1" | Should Be $true
                (nvm ls "v8").Version -contains "v8.4.0" | Should Be $true
                (nvm ls "v8").Version -contains "v8.3.0" | Should Be $true
                (nvm ls "v8").Version -contains "v0.8.0" | Should Be $false
                (nvm ls "v8").Version -contains "v7.10.0" | Should Be $false

                Assert-MockCalled Get-ChildItem -Times 1
            }
        }

        Context "When called with Filter=8" {
            It "should list installed folders matching 8" {
                (nvm ls "8").Version -contains "v8.4.1" | Should Be $true
                (nvm ls "8").Version -contains "v8.4.0" | Should Be $true
                (nvm ls "8").Version -contains "v8.3.0" | Should Be $true
                (nvm ls "8").Version -contains "v0.8.0" | Should Be $false
                (nvm ls "8").Version -contains "v7.10.0" | Should Be $false

                Assert-MockCalled Get-ChildItem -Times 1
            }
        }

        Context "When called with Filter=8.4" {
            It "should list installed folders matching 8.4" {
                (nvm ls "8.4").Version -contains "v8.4.1" | Should Be $true
                (nvm ls "8.4").Version -contains "v8.4.0" | Should Be $true
                (nvm ls "8.4").Version -contains "v8.3.0" | Should Be $false
                (nvm ls "8.4").Version -contains "v0.8.0" | Should Be $false
                (nvm ls "8.4").Version -contains "v7.10.0" | Should Be $false

                Assert-MockCalled Get-ChildItem -Times 1
            }
        }

        Context "When called with Filter=8.4.0" {
            It "should list installed folders matching 8.4.0" {
                (nvm ls "8.4.0").Version -contains "v8.4.1" | Should Be $false
                (nvm ls "8.4.0").Version -contains "v8.4.0" | Should Be $true
                (nvm ls "8.4.0").Version -contains "v8.3.0" | Should Be $false
                (nvm ls "8.4.0").Version -contains "v0.8.0" | Should Be $false
                (nvm ls "8.4.0").Version -contains "v7.10.0" | Should Be $false

                Assert-MockCalled Get-ChildItem -Times 1
            }
        }
    }
}

Start-Sleep 5
