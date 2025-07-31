module.exports = function({ types: t }) {
    return {
        visitor: {
            ArrowFunctionExpression(path) {
                // Ensure the function has at least two parameters: ctx and next
                if (path.node.params.length < 2) {
                    return;
                }
                const [param1, param2] = path.node.params;
                if (!t.isIdentifier(param1, { name: "ctx" }) || !t.isIdentifier(param2, { name: "next" })) {
                    return;
                }

                // Check that the body is a call expression to bw_serve_command_awaiter
                if (!t.isCallExpression(path.node.body)) {
                    return;
                }
                const callExpr = path.node.body;
                if (callExpr.callee.name !== 'bw_serve_command_awaiter' && callExpr.callee.name !== 'serve_command_awaiter') {
                    return;
                }

                // Grab the last argument, which should be the generator function (callback)
                const args = callExpr.arguments;
                if (args.length === 0) {
                    return;
                }
                const lastArg = args[args.length - 1];
                if (!(t.isFunctionExpression(lastArg) || t.isArrowFunctionExpression(lastArg))) {
                    return;
                }
                if (!lastArg.generator || !t.isBlockStatement(lastArg.body)) {
                    return;
                }

                // --- Build the inner API key check ---
                // Construct: process.env.BITSAILOR_BW_API_KEY
                const processEnvAPIKey = t.memberExpression(
                    t.memberExpression(t.identifier("process"), t.identifier("env")),
                    t.identifier("BITSAILOR_BW_API_KEY")
                );

                // Create the member expression for: ctx.headers['authorization']
                const apiKeyMember = t.memberExpression(
                    t.memberExpression(t.identifier("ctx"), t.identifier("headers")),
                    t.stringLiteral("authorization"),
                    true  // computed: true to use a string literal key
                );

                // Build condition: !ctx.headers['authorization']
                const notApiKey = t.unaryExpression("!", apiKeyMember, true);

                // Build condition: ctx.headers['authorization'] !== process.env.BITSAILOR_BW_API_KEY
                const apiKeyNotMatch = t.binaryExpression("!==", apiKeyMember, processEnvAPIKey);

                // Combine conditions with logical OR: !ctx.headers['authorization'] || (ctx.headers['authorization'] !== process.env.BITSAILOR_BW_API_KEY)
                const innerCondition = t.logicalExpression("||", notApiKey, apiKeyNotMatch);

                // Build the inner if block:
                // {
                //   ctx.status = 403;
                //   this.serviceContainer.logService.warning("Invalid API Key");
                //   return;
                // }
                const innerIfBlock = t.blockStatement([
                    t.expressionStatement(
                        t.assignmentExpression(
                            "=",
                            t.memberExpression(t.identifier("ctx"), t.identifier("status")),
                            t.numericLiteral(403)
                        )
                    ),
                    t.expressionStatement(
                        t.callExpression(
                            t.memberExpression(
                                t.memberExpression(
                                    t.memberExpression(t.thisExpression(), t.identifier("serviceContainer")),
                                    t.identifier("logService")
                                ),
                                t.identifier("warning")
                            ),
                            [t.stringLiteral("Invalid API Key")]
                        )
                    ),
                    t.returnStatement()
                ]);

                // Create the inner if-statement:
                const innerIfStatement = t.ifStatement(innerCondition, innerIfBlock);

                // Build the outer if-statement: if (process.env.BITSAILOR_BW_API_KEY) { ... }
                const outerBlock = t.blockStatement([innerIfStatement]);
                const outerIfStatement = t.ifStatement(processEnvAPIKey, outerBlock);

                // --- Insert the new API key check ---
                // Prepend the outer if-statement to the beginning of the generator function body
                lastArg.body.body.unshift(outerIfStatement);
            }
        }
    };
};
