# Keycloak

# URLs

Staging: https://staging.cell-a.openbraininstitute.org/auth
Production: https://cell-a.openbraininstitute.org/auth

# User registration disabled in staging

In staging, new users aren't able to register on the platform: staging is only meant to be used by the existing set of users which consists of OBI employees and a bunch of test accounts.

In case you want to disable this temporarily:

1. Open the Keycloak admin console at https://staging.cell-a.openbraininstitute.org/auth/admin/
2. Switch to the SBO realm: click on 'Realms' and click on 'SBO'
3. Click on 'Identity Providers'
4. Click on the provider which needs to be changed, for example 'github'
5. Change the option 'First login flow override': if it's set to 'First Broker login - only existing', then new users can't join the platform. If it's set to an empty value, then new users can register.
