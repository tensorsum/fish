# fish
 
Fish is a wrapper engine around Watir.

Web automations ('plays') are expressed in YAML files.
Designed to be minimalistic, extendable, polyglot.
Influenced by Squish (by FrogLogic) and Ansible.
License is BSD.


The combination I use is:

- Windows: "Windows Server 2012 R2 Datacenter"
- Ruby 2.2.5 (http://rubyinstaller.org)
- Watir (gem install watir)
- Google chrome ( MS IE )
- Perl 5 version 24 (http://www.activestate.com/activeperl)


Use: perl fish.pl hello.yml

The play will 

- open the new instance of Chrome browser
- go to Google home page
- enter "Hello World" into text field
- click the Search button 
- print the results (html stripped)
- exit the Chrome browser

Oct 02 2016

