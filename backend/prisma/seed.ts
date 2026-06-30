import { prisma } from '../src/db';

// Increment 0: no seed data yet. The placement question bank is added in Increment 1.
async function main() {
  console.log('Seed: nothing to seed in Increment 0.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
