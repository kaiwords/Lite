// Runs every phase in FK-safe order, sharing the same --env-file/--commit
// flags each phase script reads off process.argv individually.
const phases = [
  ['1/6 users', './01-users.mjs'],
  ['2/6 posts', './02-posts.mjs'],
  ['3/6 comments', './03-comments.mjs'],
  ['4/6 follows', './04-follows.mjs'],
  ['5/6 marketplace listings', './05-marketplace-listings.mjs'],
  ['6/6 conversations + messages', './06-conversations-messages.mjs'],
];

for (const [label, modulePath] of phases) {
  console.log(`\n########## ${label} ##########`);
  await import(modulePath);
}
