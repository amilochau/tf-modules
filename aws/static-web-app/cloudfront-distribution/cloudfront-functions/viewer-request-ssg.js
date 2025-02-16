function handler(event) {
    var request = event.request;
    var uri = request.uri;
    var headers = request.headers;
    var cookies = request.cookies;
    var supportedLangs = { en: true, fr: true };

    // === Allow direct access to files with extensions ===
    if (/\.(?!html)\w+$/i.test(uri)) {
        return request;
    }
    
    // Determine language: cookie first, then Accept-Language header
    var lang = (cookies && cookies['nf_lang'] && cookies['nf_lang'].value) || '';
    if (!lang) {
        lang = (headers && headers['accept-language'] && headers['accept-language'].value) || '';
    }
    
    lang = lang.toLowerCase();
    lang = lang.startsWith('fr') ? 'fr' : 'en';

    // === Normalization Phase ===
    // 1. If the URI is exactly "/", redirect to "/{lang}" (temporary)
    if (uri === '/') {
        return {
            statusCode: 302,
            statusDescription: 'Found',
            headers: { location: { value: '/' + lang } },
        };
    }
    
    // 2. Remove trailing slash (for SEO, permanent redirect)
    if (uri.endsWith('/')) {
        return {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: { location: { value: uri.slice(0, -1) } },
        };
    }
    
    var parts = uri.split('/');
    var firstSegment = parts[1];
    var lastSegment = parts[parts.length - 1];
    var sanitizedUri = uri;
    
    if (!(firstSegment in supportedLangs)) {
        sanitizedUri = '/' + lang + sanitizedUri;
    }
    sanitizedUri = sanitizedUri.replace(/\.html$/i, '').replace(/\/index$/i, '').replace(/\/$/, '');
    
    if (uri !== sanitizedUri) {
        return {
            statusCode: 302,
            statusDescription: 'Found',
            headers: { location: { value: sanitizedUri } },
        };
    }
    
    // If the URI is exactly "/{lang}" (e.g. "/en"), then internally rewrite to "/{lang}/index.html"
    if (parts.length === 2) {
        request.uri = uri + '/index.html';
        return request;
    }
    
    // For any language-prefixed URI that does not contain a file extension, internally rewrite the request by appending ".html"
    if (lastSegment.indexOf('.') === -1) {
        request.uri = uri + '.html';
        return request;
    }
    
    // Default: return the request unchanged
    return request;
}