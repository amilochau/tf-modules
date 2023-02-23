"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
exports.handler = async (event) => {
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
