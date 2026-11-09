import { parse } from "ts-command-line-args";

export interface INetworkArgs {
  network?: string;
  help?: boolean;
}

export function parseNetworkArgs(): INetworkArgs {
  const args = parse<INetworkArgs>({
    network: { type: String, optional: true, description: `network as configured in config/default.json` },
    help: { type: Boolean, optional: true, alias: 'h', description: 'Prints this usage guide' }
  }, { partial: true });

  return args;
}
