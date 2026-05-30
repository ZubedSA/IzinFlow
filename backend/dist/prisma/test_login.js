"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const bcrypt = require("bcrypt");
async function test() {
    console.log('Testing bcrypt library load...');
    try {
        const hash = await bcrypt.hash('test1234', 10);
        console.log('HASH SUCCESS:', hash);
        const match = await bcrypt.compare('test1234', hash);
        console.log('COMPARE SUCCESS:', match);
    }
    catch (err) {
        console.error('BCRYPT ERROR DETECTED:', err);
    }
}
test();
//# sourceMappingURL=test_login.js.map