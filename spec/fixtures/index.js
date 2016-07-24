/**
 * @param {string} foo Is a string
 */
function someFunction (foo) {
    console.log(foo);
}

/**
 * @desc I'm a description
 * @param {*} somebody - Whatever you want.
 * @param {boolean} bar - Something
 * @returns {string} some string
 * @callback requestCallback
 */
function sayHello (somebody) {
    console.log('Hello ' + JSON.stringify(somebody));
}

/** */
class Test {

}

/**
 * A test module foo
 * @version 1.0
 * @exports mystuff/foo
 * @namespace foo
 */
var foo = {
    /**
     * A method in first level, just for test
     * @memberof foo
     * @method testFirstLvl
     */
    testFirstLvl: function(msg) {},
    /**
     * Test child object with child namespace
     * @memberof foo
     * @type {object}
     * @namespace foo.bar
     */
    bar: {
        /**
         * A Test Inner method in child namespace
         * @memberof foo.bar
         * @method baz
         */
        baz: function() { /*...*/ }
    },
    /**
     * Test child object without namespace
     * @memberof foo
     * @type {object}
     * @property {method} baz2 A child method as property defination
     */
    bar2: {
        /**
         * A Test Inner method
         * @memberof foo.bar2
         * @method baz2
         */
        baz2: function() { /*...*/ }
    },
    /**
     * Test child object with namespace and property def.
     * @memberof foo
     * @type {object}
     * @namespace foo.bar3
     * @property {method} baz3 A child method as property defination
     */
    bar3: {
        /**
         * A Test Inner method in child namespace
         * @memberof foo.bar3
         * @method baz3
         */
        baz3: function() { /*...*/ }
    },
    /**
     * Test child object
     * @memberof foo
     * @type {object}
     * @property {method} baz4 A child method
     */
    bar4: {
         /**
         * The @alias and @memberof! tags force JSDoc to document the
         * property as `bar4.baz4` (rather than `baz4`) and to be a member of
         * `Data#`. You can link to the property as {@link foo#bar4.baz4}.
         * @alias bar4.baz4
         * @memberof! foo#
         * @method bar4.baz4
         */
        baz4: function() { /*...*/ }
    }
};