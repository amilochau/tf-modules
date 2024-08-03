export const get = async (event, context) => {
    console.warn({ event })
    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            message: "hello world"
        })
    };
};
