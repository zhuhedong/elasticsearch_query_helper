# Elasticsearch Authentication Troubleshooting Guide

## Common 401 Authentication Errors

### Error: "invalid basic authentication header encoding"

**Cause**: Incorrect base64 encoding of username:password credentials

**Solution**:
1. ✅ **Fixed in v1.0.1**: Application now uses proper `base64Encode(utf8.encode())` instead of `Uri.encodeFull()`
2. Ensure username and password don't contain special characters that could cause encoding issues
3. Verify credentials are correct in Elasticsearch

**Before (Incorrect)**:
```dart
final encoded = Uri.encodeFull(credentials); // ❌ Wrong
```

**After (Correct)**:
```dart
final encoded = base64Encode(utf8.encode(credentials)); // ✅ Correct
```

### Error: "illegal base64 character 3a"

**Cause**: Colon character (:) not properly encoded in base64

**Solution**:
- ✅ **Fixed**: Application now properly encodes the entire "username:password" string
- The colon separator is now included in the base64 encoding process

### Error: API Key Authentication Issues

**Common Problems**:
1. Using `Bearer` instead of `ApiKey` prefix
2. Using `id:secret` format instead of base64-encoded key
3. Extra spaces or characters in the key

**Correct Format**:
```
Authorization: ApiKey <base64_encoded_key>
```

## Testing Your Authentication

### Using the Application
1. **Real-time Validation**: The app now shows authentication validation as you type
2. **Preview Mode**: Enable "Show authentication header preview" to see exactly what will be sent
3. **Error Messages**: Clear error messages with suggestions for fixes

### Manual Testing
```bash
# Test basic authentication
echo -n "username:password" | base64
# Should output clean base64 string

# Test with curl
curl -u username:password http://localhost:9200/
curl -H "Authorization: Basic <base64_string>" http://localhost:9200/

# Test API key
curl -H "Authorization: ApiKey <api_key>" http://localhost:9200/
```

## Application Features for Authentication

### 1. Real-time Validation
- ✅ Validates credentials as you type
- ✅ Shows clear error messages
- ✅ Provides suggestions for fixes

### 2. Authentication Preview
- ✅ Shows exactly what header will be sent
- ✅ Helps debug encoding issues
- ✅ Validates base64 format

### 3. Enhanced Error Handling
- ✅ Specific 401 error messages
- ✅ Troubleshooting suggestions
- ✅ Debug output in development mode

## Elasticsearch Security Configuration

### Basic Authentication Setup
```yaml
# elasticsearch.yml
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: false
xpack.security.http.ssl.enabled: false
```

### Creating Users
```bash
# Create user with superuser role
bin/elasticsearch-users useradd myuser -p mypassword -r superuser

# Or use Kibana UI for user management
```

### API Key Setup
```bash
# Create API key via Elasticsearch API
POST /_security/api_key
{
  "name": "my-app-key",
  "role_descriptors": {
    "my_role": {
      "cluster": ["monitor"],
      "index": [
        {
          "names": ["*"],
          "privileges": ["read", "write"]
        }
      ]
    }
  }
}
```

## Quick Fixes Checklist

- [ ] ✅ **Updated to v1.0.1** with proper base64 encoding
- [ ] Verified username and password are correct
- [ ] Checked for special characters in credentials
- [ ] Confirmed Elasticsearch security is enabled
- [ ] Tested with curl command first
- [ ] Used authentication preview in the app
- [ ] Checked Elasticsearch logs for detailed errors

## Still Having Issues?

1. **Enable Debug Mode**: Run `./run.sh dev` to see detailed authentication debug output
2. **Check Elasticsearch Logs**: Look for specific error messages in ES logs
3. **Test with Curl**: Verify credentials work outside the application
4. **Use Authentication Preview**: Enable the preview to see exact headers being sent

## Version History

- **v1.0.0**: Initial release with authentication issues
- **v1.0.1**: ✅ **Fixed base64 encoding bug**, added real-time validation and preview