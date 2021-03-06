Feature: Manage Providers
  In order to manage my cloud infrastructure
  As a user
  I want to manage cloud providers

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: List providers
    Given I am on the homepage
    And there are these providers:
    | name      |
    | provider1 |
    | provider2 |
    | provider3 |
    When I go to the providers page
    Then I should see the following:
    | provider1 |
    | provider2 |
    | provider3 |

  Scenario: List providers in XML format
    Given I accept XML
    And there are these providers:
    | name      |
    | provider1 |
    | provider2 |
    | provider3 |
    When I go to the providers page
    Then I should get a XML document
    And XML should contain 3 providers
    And each provider should have "name"
    And each provider should have "url"
    And each provider should have "provider_type"
    And there should be these provider:
    | name         | url                       | provider_type |
    | provider1    | http://localhost:3002/api | mock          |
    | provider2    | http://localhost:3002/api | mock          |
    | provider3    | http://localhost:3002/api | mock          |

  Scenario: Show provider details
    Given there is a provider named "testprovider"
    When I am on the testprovider's edit provider page
    Then I should see "Provider name"
    And I should see "Provider URL"

  Scenario: Create a new Provider
    Given I am on the new provider page
    And I attempt to add a valid provider
    Then I should be on the testprovider's edit provider page
    And I should see a confirmation message
    And I should have a provider named "testprovider"

  Scenario: Create a new Provider failure when using wrong url
    Given I am on the new provider page
    And I attempt to add a provider with an invalid url
    Then I should be on the providers page
    And I should see a warning message

  Scenario: Delete a provider
    Given I am on the homepage
    And there is a provider named "provider1"
    And this provider has 5 hardware profiles
    And this provider has a realm
    And this provider has a provider account
    When I go to the provider1's edit provider page
    And I follow "delete"
    And there should not exist a provider named "provider1"
    And there should not be any hardware profiles
    And there should not be a provider account
    And there should not be a realm

  Scenario: Disable a provider
    Given there is a provider named "provider1"
    And this provider has a provider account with 2 running instances
    When I go to the provider1's edit provider page
    And I press "provider_submit"
    Then I should be on the provider1's edit provider page
    And I should see "Provider is disabled."
    And I should not see "Error while stopping an instance"

  Scenario: Disable an inaccessible provider
    Given there is a provider named "provider1"
    And this provider has a provider account with 2 running instances
    And provider "provider1" is not accessible
    When I go to the provider1's edit provider page
    And I press "provider_submit"
    Then I should see "Provider is not accessible, status of following instances will be changed to 'stopped'"
    When I press "disable_button"
    Then I should be on the provider1's edit provider page
    And I should see "Provider is disabled."
    And provider "provider1" should have all instances stopped

#  Scenario: Search for hardware profiles
#    Given there are these providers:
#    | name          | url                         |
#    | Test          | http://testprovider.com/api |
#    | Kenny         | http://mockprovider.com/api |
#    | Other         | http://sometesturl.com/api  |
#    And I am on the providers page
#    Then I should see the following:
#    | Test  | http://testprovider.com/api |
#    | Kenny | http://mockprovider.com/ap  |
#    | Other | http://sometesturl.com/api  |
#    When I fill in "q" with "test"
#    And I press "Search"
#    Then I should see "Test"
#    And I should see "Other"
#    And I should not see "Kenny"
#    When I fill in "q" with "Kenny"
#    And I press "Search"
#    Then I should see "Kenny"
#    And I should not see "Test"
#    And I should not see "Other"
