.pragma library

// Frecency the way z (rupa/z) ranks directories for cd: how often, weighted
// by how recently. Pure functions over a plain object, so Usage.qml owns the
// file and Menu.qml the ordering, and neither has to know the arithmetic.
//
//   db = { "<key>": { rank: <number>, time: <unix seconds> }, ... }
//
// Every use adds 1 to the key's rank. A key's score is its rank times a
// weight for the time since its last use, z's own four steps. When the ranks
// add up past maxTotal, every rank is multiplied by 0.99 and any that fall
// under 1 are forgotten, so the list ages instead of growing forever. z ages
// at 9000 over a whole filesystem; a menu has a few hundred entries.

var maxTotal = 1000;

function weight(ageSeconds) {
    if (ageSeconds < 3600)
        return 4;
    if (ageSeconds < 86400)
        return 2;
    if (ageSeconds < 604800)
        return 0.5;
    return 0.25;
}

function score(db, key, now) {
    var entry = key ? db[key] : undefined;
    return entry ? entry.rank * weight(now - entry.time) : 0;
}

function total(db) {
    return Object.keys(db).reduce(function (sum, key) { return sum + db[key].rank; }, 0);
}

function aged(db) {
    return Object.keys(db).reduce(function (out, key) {
        var rank = db[key].rank * 0.99;
        if (rank >= 1)
            out[key] = { rank: rank, time: db[key].time };
        return out;
    }, {});
}

// Returns a new db with the use recorded; the old one is left as it was.
function record(db, key, now) {
    var next = Object.assign({}, db);
    next[key] = { rank: (db[key] ? db[key].rank : 0) + 1, time: now };
    return total(next) > maxTotal ? aged(next) : next;
}

// What frecency adds to a search hit. Logarithmic, so the hundredth launch
// counts for less than the second. Match tiers in MenuTree.score are 100
// apart, and the cap sits between one and two tiers, so use can lift a hit
// past a better-matching one by one tier and never by two. Used once long
// ago adds about 9, once in the last hour 64, ten times today 122.
function bonus(db, key, now) {
    return Math.min(150, 40 * Math.log(1 + score(db, key, now)));
}
