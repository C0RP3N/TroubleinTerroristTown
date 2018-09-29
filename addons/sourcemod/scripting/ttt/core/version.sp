void GetLatestVersion()
{
    char sURL[64];
    Format(sURL, sizeof(sURL), "https://csgottt.com/version.php");

    Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sURL);
    bool bTimeout = SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 10);
    bool bCallback = SteamWorks_SetHTTPCallbacks(hRequest, OnHTTPCallback);

    if(!bTimeout || !bCallback)
    {
        LogError("[TTT] (GetLatestVersion) Error in setting request properties, cannot send request");
        delete hRequest;
        return;
    }

    bool bRequest = SteamWorks_SendHTTPRequest(hRequest);
    if (!bRequest)
    {
        LogError("[TTT] (GetLatestVersion) Can't send request!");
        delete hRequest;
        return;
    }

    SteamWorks_PrioritizeHTTPRequest(hRequest);
}

public void OnHTTPCallback(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    if (!bRequestSuccessful || bFailure)
    {
        LogError("[TTT] (OnHTTPCallback) Error... bRequestSuccessful: %d, bFailure: %d", bRequestSuccessful, bFailure);
        delete hRequest;
        return;
    }

    if (eStatusCode != k_EHTTPStatusCode200OK)
    {
        LogError("[TTT] (OnHTTPCallback) Something went wrong.... Status Code: %d!", eStatusCode);
        delete hRequest;
        return;
    }

    int iSize = -1;

    bool bBody = SteamWorks_GetHTTPResponseBodySize(hRequest, iSize);
    if (!bBody)
    {
        LogError("[TTT] (OnHTTPCallback] Can't get body size!");
        delete hRequest;
        return;
    }
    else if (iSize < 2 || iSize > 64)
    {
        LogError("[TTT] (OnHTTPCallback) Invalid body size (%d)!", iSize);
        delete hRequest;
        return;
    }

    char sVersion[64];
    bool bData = SteamWorks_GetHTTPResponseBodyData(hRequest, sVersion, iSize);
    if (!bData)
    {
        LogError("[TTT] (OnHTTPCallback) Failure with body data!");
        delete hRequest;
        return;
    }

    TrimString(sVersion);

    if (GetCharBytes(sVersion[2]) == 4)
    {
        strcopy(g_sLatestVersion, sizeof(g_sLatestVersion), sVersion[3]);
    }

    Call_StartForward(g_hOnVersionCheck);
    Call_PushString(g_sLatestVersion);
    Call_Finish();

    delete hRequest;
}
