
-- The following PL/SQL block uses `APEX_WEB_SERVICE.MAKE_REST_REQUEST` to POST a JSON payload to the Discord webhook. Replace the placeholder URL and bot user ID before running:

plsql
DECLARE
  l_url      VARCHAR2(4000) := 'DISCORD_WEBHOOK_URL';
  l_payload  CLOB           := '{
    "username": "DB Alert Bot",
    "content": "<@BOT_USER_ID> Apex Test Message"
  }';
  l_response CLOB;
BEGIN
  apex_web_service.g_request_headers.delete();
  apex_web_service.g_request_headers(1).name  := 'Content-Type';
  apex_web_service.g_request_headers(1).value := 'application/json';

  l_response := APEX_WEB_SERVICE.MAKE_REST_REQUEST(
    p_url         => l_url,
    p_http_method => 'POST',
    p_body        => l_payload
  );

  IF l_response IS NULL OR LENGTH(l_response) = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Success: HTTP 204 (No Content) - message sent!');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Unexpected response: ' || DBMS_LOB.SUBSTR(l_response, 1000, 1));
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    RAISE;
END;
/

-- A successful call returns HTTP 204 No Content, so 'l_response' will be null or empty. If you receive 'ORA-24247', check network ACL configuration for your ADB instance.